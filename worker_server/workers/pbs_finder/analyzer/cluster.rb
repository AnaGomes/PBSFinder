module Pbs
  module Analyzer
    # Gene and protein clustering analysis.
    class Cluster
      def initialize(helper = nil, config = nil)
        @helper = helper

        # Start RServe.
        @r = Rserve::Simpler.new
        @r.command('library(cluster)')
        #@r.command('library(fpc)')
        @r.command('library(arules)')
        @r.command('library(ade4)')
      end

      # Cluster genes solely based on RBP occurrences; applies same minimum
      # information limits as other clustering analysis.
      def cluster_genes_quant!(job)
      end

      # Compute similarities and dissimilarities between proteins and genes.
      def find_similarities!(job)
        job.cluster_info.each do |cluster|
          # Find similarities between objects in clusters.
          find_protein_similarities!(job, cluster)
          find_gene_similarities!(job, cluster)
        end

        # Sort clusters by best average silhouette.
        job.cluster_info.sort! { |c1, c2| (c2.silhouette + c2.gene_silhouette) / 2.0 <=> (c1.silhouette + c1.gene_silhouette) / 2.0 }

        # Compute average silhouette.
        average = 0.0
        count = 0
        job.cluster_info.each do |c|
          average += (c.silhouette + c.gene_silhouette) / 2.0
          count += 1
        end
        average /= count.to_f

        # Select best clusters.
        clusters = job.cluster_info.select do |c|
          res = (c.silhouette + c.gene_silhouette) / 2.0 >= average
          next unless res
          gene_arys = {}
          protein_arys = {}
          c.gene_sims.each { |cls, attrs| attrs.each { |_, values| gene_arys[cls] ||= []; gene_arys[cls].concat(values) } }
          c.protein_sims.each { |cls, attrs| attrs.each { |_, values| protein_arys[cls] ||= []; protein_arys[cls].concat(values) } }
          gene_max = gene_arys.max_by { |_, ary| ary.size }[1].size * @helper.config[:cluster][:min_max_attrs]
          protein_max = protein_arys.max_by { |_, ary| ary.size }[1].size * @helper.config[:cluster][:min_max_attrs]
          res &= gene_arys.all? { |_, ary| ary.size >= gene_max }
          res &= protein_arys.all? { |_, ary| ary.size >= protein_max }
          res
        end
        clusters += job.cluster_info.select do |c|
          res = (c.silhouette + c.gene_silhouette) / 2.0 >= average
          res &= c.gene_sims.inject(true) { |v, (_, attrs)| v &= attrs.all? { |_, values| values.size > 0 }; v }
          res &= c.protein_sims.inject(true) { |v, (_, attrs)| v &= attrs.all? { |_, values| values.size > 0 }; v }
          res
        end
        job.cluster_info.each do |c|
          break unless clusters.size < @helper.config[:cluster][:max_clusters]
          clusters << c unless clusters.include?(c)
        end
        job.cluster_info = clusters[0...@helper.config[:cluster][:max_clusters]]
      end

      # Cluster genes based on protein clusters.
      def cluster_genes!(job)
        # Build gene/protein table.
        genes = {}
        job.cluster_proteins.each do |_, prot|
          prot.genes.each do |gene|
            #genes[gene.gene_id] ||= { pathways: [], pathway_names: [], proteins: Set.new, gene: gene }
            genes[gene.gene_id] ||= { proteins: Set.new, gene: gene }
            genes[gene.gene_id][:proteins].add(prot.protein.protein_id)
            #gene.transcripts.each do |_, trans|
              #if trans.own_protein
                #genes[gene.gene_id][:pathways].concat(trans.own_protein.pathways.keys)
                #genes[gene.gene_id][:pathway_names].concat(trans.own_protein.pathways.values)
              #end
            #end
          end
        end
        job.cluster_genes = genes

        # Apply every possible clustering combination.
        info = []
        job.cluster_info.each do |cls|
          info.concat(cluster_by_gene(job, cls, genes))
        end
        job.cluster_info = info
      end

      # Find all cluster combination for proteins.
      def cluster_proteins!(job)
        clusters = []
        attrs = [:keywords, :tissues, :pathways, :biological_process, :cellular_component, :molecular_function]
        attrs = (2..attrs.size).inject([]) { |ary, n| ary.concat(attrs.combination(n).to_a) }
        attrs.each do |attr|
          clusters.concat(cluster_by_protein(job, attr, :binary, :pam))
          clusters.concat(cluster_by_protein(job, attr, :binary, :hclust))
          clusters.concat(cluster_by_protein(job, attr, :jaccard, :pam))
          clusters.concat(cluster_by_protein(job, attr, :jaccard, :hclust))
        end
        job.cluster_info = clusters
      end

      # Prepares dataset for clustering analysis.
      def clean_dataset!(job)
        # Remove useless proteins (no ID).
        #proteins = job.proteins.select { |p| p.protein_id }.uniq { |p| p.protein_id }
        proteins = []
        job.genes.each do |gene|
          gene.transcripts.each do |_, trans|
            trans.proteins.each do |_, prot|
              if prot.protein_id
                proteins << prot
              end
            end
          end
        end
        proteins.uniq! { |p| p.protein_id }
        proteins.map! { |p| Container::ClusterProtein.new(protein: p) }

        # Remove frequent proteins (>= 95%).
        proteins.each do |prot|
          job.genes.each do |gene|
            gene.transcripts.each do |_, trans|
              #if trans.own_protein && trans.own_protein.protein_id == prot.protein.protein_id
                #prot.genes << gene
              if trans.proteins.values.map { |p| p.protein_id }.include?(prot.protein.protein_id)
                prot.genes << gene
              end
            end
          end
        end
        # TODO Uncomment to remove frequent proteins.
        # proteins.reject! { |p| (p.genes.size.to_f / job.genes.size.to_f) >= @helper.config[:cluster][:perc_protein_reject] }

        # Convert long string attributes to standardized format and remove
        # frequent attributes (>= 95%).
        build_attr_converter!(job, proteins)

        # Build usable attributes for each protein.
        build_usable_attr!(job, proteins)
        job.cluster_proteins = proteins.inject({}) do |h, p|
          h[p.protein.protein_id] = p
          h
        end

        # Check clustering feasibility.
        genes = Set.new
        proteins.each do |prot|
          genes.merge(prot.genes)
        end
        genes.size >= @helper.config[:cluster][:min_genes] && proteins.size >= @helper.config[:cluster][:min_proteins]
      end

      private

      # Compute similarities between proteins.
      def find_protein_similarities!(job, cluster)
        # Build similarities.
        perc = @helper.config[:cluster][:perc_frequent_attr]
        all_value = false
        while perc >= 0.5 && !all_value
          sims = cluster.clusters.inject({}) do |h, (_, cls)|
            h[cls] = { keywords: [], pathways: [], tissues: [], biological_process: [], cellular_component: [], molecular_function: [] }
            h
          end
          cluster.clusters.each do |name, cls|
            prot = job.cluster_proteins[name]
            sims[cls][:keywords].concat(prot.protein.keywords)
            sims[cls][:pathways].concat(prot.protein.pathways.values)
            sims[cls][:tissues].concat(prot.protein.tissues)
            sims[cls][:biological_process].concat(prot.protein.biological_process)
            sims[cls][:cellular_component].concat(prot.protein.cellular_component)
            sims[cls][:molecular_function].concat(prot.protein.molecular_function)
          end

          # Leave only very frequent attributes.
          sims.each do |cls, attrs|
            total = cluster.n_clusters[cls].to_f
            attrs.each do |attr, values|
              attrs[attr] = count_occurrences(values).reject { |_, count| (count.to_f / total) < perc }
            end
          end

          # Remove shared frequent attributes.
          sims.each do |c1, attrs1|
            sims.each do |c2, attrs2|
              next if c1 == c2
              attrs1.each do |attr, values|
                values.each do |v, _|
                  if attrs2[attr].key?(v)
                    attrs1[attr][v] = nil
                    attrs2[attr][v] = nil
                  end
                end
              end
            end
          end

          # Check if all there is at least one defining attribute for each
          # cluster.
          all_value = true
          sims.each do |_, attrs|
            all_value &= attrs.inject(false) do |b, (_, values)|
              b |= values.values.any?
              b
            end
          end
          unless all_value
            perc -= 0.05
          end
        end

        # Clean attributes.
        sims.each do |_, attrs|
          attrs.each do |attr, values|
            attrs[attr] = values.inject([]) do |ary, (a, v)|
              ary << a if v
              ary
            end
          end
        end
        cluster.protein_sims = sims
      end

      # Compute similarities between gene.
      def find_gene_similarities!(job, cluster)
        # Build similarities.
        perc = @helper.config[:cluster][:perc_frequent_attr]
        all_value = false
        while perc >= 0.5 && !all_value
          sims = cluster.gene_clusters.inject({}) do |h, (_, cls)|
            h[cls] = { keywords: [], pathways: [], tissues: [], biological_process: [], cellular_component: [], molecular_function: [] }
            h
          end
          cluster.gene_clusters.each do |name, cls|
            temp = { keywords: [], pathways: [], tissues: [], biological_process: [], cellular_component: [], molecular_function: [] }
            job.cluster_genes[name][:proteins].each do |p|
              prot = job.cluster_proteins[p]
              temp[:keywords].concat(prot.protein.keywords)
              temp[:pathways].concat(prot.protein.pathways.values)
              temp[:tissues].concat(prot.protein.tissues)
              temp[:biological_process].concat(prot.protein.biological_process)
              temp[:cellular_component].concat(prot.protein.cellular_component)
              temp[:molecular_function].concat(prot.protein.molecular_function)
            end
            sims[cls][:keywords].concat(temp[:keywords].uniq)
            sims[cls][:pathways].concat(temp[:pathways].uniq)
            sims[cls][:tissues].concat(temp[:tissues].uniq)
            sims[cls][:biological_process].concat(temp[:biological_process].uniq)
            sims[cls][:cellular_component].concat(temp[:cellular_component].uniq)
            sims[cls][:molecular_function].concat(temp[:molecular_function].uniq)
          end

          # Leave only very frequent attributes.
          sims.each do |cls, attrs|
            total = cluster.gene_n_clusters[cls].to_f
            attrs.each do |attr, values|
              attrs[attr] = count_occurrences(values).reject { |_, count| (count.to_f / total) < perc }
            end
          end

          # Remove shared frequent attributes.
          sims.each do |c1, attrs1|
            sims.each do |c2, attrs2|
              next if c1 == c2
              attrs1.each do |attr, values|
                values.each do |v, _|
                  if attrs2[attr].key?(v)
                    attrs1[attr][v] = nil
                    attrs2[attr][v] = nil
                  end
                end
              end
            end
          end

          # Check if all there is at least one defining attribute for each
          # cluster.
          all_value = true
          sims.each do |_, attrs|
            all_value &= attrs.inject(false) do |b, (_, values)|
              b |= values.values.any?
              b
            end
          end
          unless all_value
            perc -= 0.05
          end
        end

        # Clean attributes.
        sims.each do |_, attrs|
          attrs.each do |attr, values|
            attrs[attr] = values.inject([]) do |ary, (a, v)|
              ary << a if v
              ary
            end
          end
        end
        cluster.gene_sims = sims
      end



      # Produce the result of clustering genes based on protein clusters.
      def cluster_by_gene(job, cluster, genes)
        # Build data.
        df = build_jaccard_gene_dataframe(job, cluster, genes)
        @r.command(df: df) do
          %Q{
            dt <- as.dist(df)
            dt[is.na(dt)] <- 0.0
          }
        end

        # Cluster with same method.
        res = []
        if cluster.algorithm == :hclust
          @r.command("h <- hclust(dt, method='average')")
          (2..10).each do |k|
            cls = @r.converse("cutree(h, k=#{k})")
            sil = @r.converse("summary(silhouette(x=cutree(h, k=#{k}),dist=dt))$avg.width")
            c = cluster.dup
            c.gene_silhouette = sil
            c.gene_clusters = cls.names.inject({}) do |h, name|
              h[name] = cls[name]
              h
            end
            c.gene_n_clusters = count_occurrences(cls)
            res << c
          end
        elsif cluster.algorithm == :pam
          (2..10).each do |k|
            pam = @r.converse("pam(dt, #{k}, diss=T)")
            cls = pam['clustering']
            sil = pam['silinfo']['avg.width']
            c = cluster.dup
            c.gene_silhouette = sil
            c.gene_clusters = cls.names.inject({}) do |h, name|
              h[name] = cls[name]
              h
            end
            c.gene_n_clusters = count_occurrences(cls)
            res << c
          end
        end
        total = df.rownames.size.to_f
        res.reject! { |c| c.gene_n_clusters.values.any? { |count| (count.to_f / total) < @helper.config[:cluster][:perc_by_cluster] } }
        res.sort! { |a, b| b.gene_silhouette <=> a.gene_silhouette }
        res.first ? [res.first] : []
      end

      # Builds a dataframe for genes with Jaccard method.
      def build_jaccard_gene_dataframe(job, cluster, genes)
        distances = {}
        genes.each do |g1, s1|
          distances[g1] ||= {}
          hits1 = build_gene_hits(g1, s1, cluster)
          genes.each do |g2, s2|
            if g1 == g2
              distances[g1][g2] = 0.0
            elsif distances[g2] && distances[g2][g1]
              distances[g1][g2] = distances[g2][g1]
            else
              hits2 = build_gene_hits(g2, s2, cluster)
              dist = cluster.n_clusters.inject({}) do |h, (cls, _)|
                d = Jaccard.distance(hits1[cls] || [], hits2[cls] || [])
                h[cls] = d.nan? ? 0.0 : d
                h
              end
              #pathways = Jaccard.distance(s1[:pathways], s2[:pathways])
              #dist[:pathways] = pathways.nan? ? 0.0 : pathways
              distances[g1][g2] = calc_array_distance(dist, :manhattan, @helper.config[:cluster][:jaccard_weight])
            end
          end
        end

        # Build dataframe.
        names = distances.keys.sort
        row = Struct.new(nil, *names)
        rows = []
        names.each do |name|
          rows << row.new(*(distances[name].sort.map { |ary| ary[1] }))
        end

        # Build dataframe.
        frame = Rserve::DataFrame.from_structs(rows)
        frame.rownames = names
        frame
      end

      # Finds all proteins for each gene, by cluster.
      def build_gene_hits(gene, set, cluster)
        hits = {}
        set[:proteins].each do |prot|
          cls = cluster.clusters[prot]
          if cls
            hits[cls] ||= []
            hits[cls] << prot
          end
        end
        hits
      end

      # Produces the result of clustering proteins with a single combination
      # set of parameters.
      def cluster_by_protein(job, attrs, type, algorithm)
        # Build distance matrix.
        df = build_dataframe(job, type, attrs)
        case type
        when :binary
          @r.command(df: df, asyma: build_asymmetric_attrs(job, attrs), syma: build_symmetric_attrs(job, attrs)) do
            %Q{
              dt <- daisy(df * 1.0, metric='gower', type=list(symm=syma, asymm=asyma))
              dt[is.na(dt)] <- 0.0
            }
          end
        when :jaccard
          @r.command(df: df) do
            %Q{
              dt <- as.dist(df)
              dt[is.na(dt)] <- 0.0
            }
          end
        end

        # Cluster by method.
        res = []
        if algorithm == :hclust
          @r.command("h <- hclust(dt, method='average')")
          (2..10).each do |k|
            cls = @r.converse("cutree(h, k=#{k})")
            sil = @r.converse("summary(silhouette(x=cutree(h, k=#{k}),dist=dt))$avg.width")
            c = Container::Cluster.new(df_type: type, attrs: attrs, algorithm: algorithm)
            c.silhouette = sil
            c.clusters = cls.names.inject({}) do |h, name|
              h[name] = cls[name]
              h
            end
            c.n_clusters = count_occurrences(cls)
            res << c
          end
        elsif algorithm == :pam
          (2..10).each do |k|
            pam = @r.converse("pam(dt, #{k}, diss=T)")
            cls = pam['clustering']
            sil = pam['silinfo']['avg.width']
            c = Container::Cluster.new(df_type: type, attrs: attrs, algorithm: algorithm)
            c.silhouette = sil
            c.clusters = cls.names.inject({}) do |h, name|
              h[name] = cls[name]
              h
            end
            c.n_clusters = count_occurrences(cls)
            res << c
          end
        end

        # Remove unwanted clustering results.
        total = df.rownames.size.to_f
        #res.sort! { |a, b| b.silhouette <=> a.silhouette }
        #res.reject { |c| c.n_clusters.values.any? { |count| (count.to_f / total) < @helper.config[:cluster][:perc_by_cluster] } } << res[0]
        res.reject! { |c| c.n_clusters.values.any? { |count| (count.to_f / total) < @helper.config[:cluster][:perc_by_cluster] } }
        res.sort! { |a, b| b.silhouette <=> a.silhouette }
        res.first ? [res.first] : []
      end

      # Creates list of assymetric attributes for the daisy method.
      def build_symmetric_attrs(job, attrs)
        res = []
        res.concat(job.attr_converter[:pathways].values) if attrs.include?(:pathways)
        res.concat(job.attr_converter[:tissues].values) if attrs.include?(:tissues)
        res
      end

      # Creates list of assymetric attributes for the daisy method.
      def build_asymmetric_attrs(job, attrs)
        res = []
        res.concat(job.attr_converter[:keywords].values) if attrs.include?(:keywords)
        res.concat(job.attr_converter[:biological_process].values) if attrs.include?(:biological_process)
        res.concat(job.attr_converter[:cellular_component].values) if attrs.include?(:cellular_component)
        res.concat(job.attr_converter[:molecular_function].values) if attrs.include?(:molecular_function)
        res
      end

      # Builds a new dataframe from the dataset.
      def build_dataframe(job, type, attributes, options = {})
        case type
        when :binary
          return build_binary_dataframe(job, attributes, options)
        when :jaccard
          return build_jaccard_dataframe(job, attributes, options)
        end
      end

      # Calculates a distance based on an array of values.
      def calc_array_distance(h, type, weight)
        case type
        when :manhattan
          return h.inject(0.0) { |d, (k, v)| d += (weight[k] || 1.0) * v }
        when :euclidean
          return Math.sqrt(h.inject(0.0) { |d, (k, v)| d += (weight[k] || 1.0) * (v**2) })
        when :squared_euclidean
          return h.inject(0.0) { |d, (k, v)| d += (weight[k] || 1.0) * (v**2) }
        end
      end

      # Creates a Jaccard distance dataframe.
      def build_jaccard_dataframe(job, attributes, options)
        distances = {}
        job.cluster_proteins.each do |_, p1|
          job.cluster_proteins.each do |_, p2|
            distances[p1.protein.protein_id] ||= {}
            if p1 == p2
              distances[p1.protein.protein_id][p2.protein.protein_id] = 0.0
            elsif distances[p2.protein.protein_id] && distances[p2.protein.protein_id][p1.protein.protein_id]
              distances[p1.protein.protein_id][p2.protein.protein_id] = distances[p2.protein.protein_id][p1.protein.protein_id]
            else
              dist = attributes.inject({}) do |h, attr|
                d = Jaccard.distance(p1.instance_variable_get("@#{ attr.to_s }"), p2.instance_variable_get("@#{ attr.to_s }"))
                h[attr] = d.nan? ? 0.0 : d
                h
              end
              distances[p1.protein.protein_id][p2.protein.protein_id] = calc_array_distance(dist, options[:type] || :manhattan, @helper.config[:cluster][:jaccard_weight])
            end
          end
        end

        # Consolidate distances.
        names = distances.keys.sort
        row = Struct.new(nil, *names)
        rows = []
        names.each do |name|
          rows << row.new(*(distances[name].sort.map { |ary| ary[1] }))
        end

        # Build dataframe.
        frame = Rserve::DataFrame.from_structs(rows)
        frame.rownames = names
        frame
      end

      # Creates a binary dataframe for analysis.
      def build_binary_dataframe(job, attributes, options)
        # Build base struct.
        headers = attributes.inject([]) { |h, attr| h.concat(job.attr_converter[attr].values.map(&:to_sym)) }
        row = Struct.new(*headers).new
        row.members.each { |m| row[m] = 0.0 }
        rows, names = [], []

        # Compile data.
        job.cluster_proteins.each do |_, prot|
          dr = row.dup
          prot.keywords.each { |x| dr[x] = 1.0 } if attributes.include?(:keywords)
          prot.tissues.each { |x| dr[x] = 1.0 } if attributes.include?(:tissues)
          prot.pathways.each { |x| dr[x] = 1.0 } if attributes.include?(:pathways)
          prot.molecular_function.each { |x| dr[x] = 1.0 } if attributes.include?(:molecular_function)
          prot.cellular_component.each { |x| dr[x] = 1.0 } if attributes.include?(:cellular_component)
          prot.biological_process.each { |x| dr[x] = 1.0 } if attributes.include?(:biological_process)
          rows << dr
          names << prot.protein.protein_id
        end

        # Build dataframe.
        frame = Rserve::DataFrame.from_structs(rows)
        frame.rownames = names
        frame
      end

      # Creates lists of usable attributes for each protein.
      def build_usable_attr!(job, proteins)
        proteins.each do |prot|
          build_attr!(prot.protein.keywords, prot.keywords, job.attr_converter[:keywords])
          build_attr!(prot.protein.tissues, prot.tissues, job.attr_converter[:tissues])
          build_attr!(prot.protein.pathways.keys, prot.pathways, job.attr_converter[:pathways])
          build_attr!(prot.protein.molecular_function, prot.molecular_function, job.attr_converter[:molecular_function])
          build_attr!(prot.protein.cellular_component, prot.cellular_component, job.attr_converter[:cellular_component])
          build_attr!(prot.protein.biological_process, prot.biological_process, job.attr_converter[:biological_process])
        end
      end

      # Creates a list for a single attribute types, based on the global
      # attribute converter.
      def build_attr!(old_attr, new_attr, converter)
        old_attr.each do |attr|
          new_attr << converter[attr] if converter[attr]
        end
      end

      # Creates the global attribute converter hash.
      def build_attr_converter!(job, proteins)
        key, pat, tis, mol, cel, bio = [], [], [], [], [], []
        job.attr_converter = {
          keywords: {},
          tissues: {},
          pathways: {},
          molecular_function: {},
          cellular_component: {},
          biological_process: {}
        }
        proteins.each do |prot|
          key.concat(prot.protein.keywords)
          tis.concat(prot.protein.tissues)
          pat.concat(prot.protein.pathways.keys)
          mol.concat(prot.protein.molecular_function)
          cel.concat(prot.protein.cellular_component)
          bio.concat(prot.protein.biological_process)
        end
        convert_attr!(key, job.attr_converter[:keywords], 'key', proteins.size)
        convert_attr!(tis, job.attr_converter[:tissues], 'tis', proteins.size)
        convert_attr!(pat, job.attr_converter[:pathways], 'pat', proteins.size)
        convert_attr!(bio, job.attr_converter[:biological_process], 'bio', proteins.size)
        convert_attr!(mol, job.attr_converter[:molecular_function], 'mol', proteins.size)
        convert_attr!(cel, job.attr_converter[:cellular_component], 'cel', proteins.size)
      end

      # Converts a single attribute type for the global attribute converter
      # hash.
      def convert_attr!(attrs, res, frag, total)
        i = 0
        attrs = dup_hash(attrs)
        attrs.each do |attr, count|
          unless (count.to_f / total.to_f) >= @helper.config[:cluster][:perc_attr_reject]
            res[attr] = "#{frag}.#{i}"
            i += 1
          end
        end
      end

      # Change "v > 1" to "v >= 1" to include single elements.
      # Counts repeated elements in an array.
      def dup_hash(ary)
        ary.inject(Hash.new(0)) { |h,e| h[e] += 1; h }.select {
          |k,v| v >= 1 }.inject({}) { |r, e| r[e.first] = e.last; r }
      end

      # Counts occurrences of each value in an array.
      def count_occurrences(ary)
        ary.inject(Hash.new(0)) { |h,e| h[e] += 1; h }.select {
          |k,v| v >= 1 }.inject({}) { |r, e| r[e.first] = e.last; r }
      end
    end
  end
end
