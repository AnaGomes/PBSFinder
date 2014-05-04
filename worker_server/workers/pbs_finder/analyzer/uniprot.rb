module Pbs
  module Analyzer
    # Establishes relationships between the obtained data and the UniProt
    # service.
    class Uniprot
      def initialize(helper = nil)
        @helper = helper
      end

      def find_uniprot_info!(job)
        # Request UniProt pages.
        response = nil
        begin
          uri = URI::HTTP.build(
            host: @helper.config[:uniprot][:url],
            path: @helper.config[:uniprot][:batch_path]
          )
          response = Net::HTTP.post_form(
            uri,
            @helper.config[:uniprot][:parameters_batch].merge({
              @helper.config[:uniprot][:parameter_query] => job.protein_ids.to_a.join(' ')
            })
          )
          while response.code == '301' || response.code == '302'
            response = Net::HTTP.get_response(URI.parse(response.header['location']))
          end
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end

        # Parse the response.
        if response && response.body && !response.body.empty?
          parse_uniprot_flatfiles!(job, response.body)
        end
      end

      def find_uniprot_ids!(job)
        # Create the queries.
        build_protein_list!(job)
        queries = build_uniprot_queries(job, 50)
        uniprots = {}

        # Parse the UniProt responses.
        begin
          queries.each do |query|
            uri = build_uniprot_uri(query)
            response = Net::HTTP.get_response(uri)
            while response.code == "301" || response.code == "302"
              response = Net::HTTP.get_response(URI.parse(response.header['location']))
            end
            if response && response.body && !response.body.empty?
              parse_uniprot_query!(response.body, uniprots)
            end
          end
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end

        # Parse UniProt request.
        begin
          parse_uniprot_response!(job, uniprots)
        rescue StandardError => e
          puts e.message, e.backtrace
        end

        # Remove any unusable proteins and build a UniProt ID list.
        build_id_list!(job)
      end

      private

      def parse_uniprot_flatfiles!(job, response)
        strio = Bio::FlatFile.open(Bio::SPTR, StringIO.new(response, 'r'))
        strio.each_entry do |flat|
          parse_uniprot_flatfile!(job, flat)
        end
      rescue StandardError => e
        puts e.message, e.backtrace
      end

      def parse_uniprot_flatfile!(job, flat)
        # ID and taxon.
        ids = flat.ac()
        taxon = flat.ox()['NCBI_TaxID'][0]

        # External IDs.
        external = {}
        flat.dr().each do |id, values|
          external[id.downcase.to_sym] = values
        end

        # Tissues.
        tissues = Set.new
        flat.ref.each do |ref|
          (ref['RC'] || []).each do |r|
            if r && r['Token'] == 'TISSUE'
              tissue = r['Text'].downcase
              tissue[0] = tissue[0].upcase
              tissues.add(tissue)
            end
          end
        end

        # Keywords and ontology.
        keywords = flat.kw
        cell_component = Set.new
        bio_process = Set.new
        mol_function = Set.new
        flat.dr('GO').each do |g|
          ont = g['Version'][2..-1]
          ont[0] = ont[0].upcase
          case g['Version'][0]
          when 'C'
            cell_component.add(ont)
          when 'F'
            mol_function.add(ont)
          when 'P'
            bio_process.add(ont)
          end
        end

        # Build protein information.
        build_protein_info!(job, {
          ids: ids,
          taxon: taxon,
          external_ids: external,
          tissues: tissues.to_a,
          keywords: keywords,
          cell_component: cell_component.to_a,
          bio_process: bio_process.to_a,
          mol_function: mol_function.to_a
        })
      end

      def build_protein_info!(job, info)
        job.proteins.each do |prot|
          # Protein matches info.
          if info[:ids].include?(prot.protein_id)
            prot.external_ids = info[:external_ids]
            prot.tissues = info[:tissues]
            prot.keywords = info[:keywords]
            prot.cellular_component = info[:cell_component]
            prot.biological_process = info[:bio_process]
            prot.molecular_function = info[:mol_function]
            prot.taxon = info[:taxon]
            prot.species = @helper.config[:taxons][info[:taxon]]
          end
        end
      end

      def build_id_list!(job)
        job.proteins.select! { |prot| prot.protein_id }
        job.proteins.each do |prot|
          job.protein_ids.add(prot.protein_id)
        end
      end

      def build_uniprot_query(job)
        query = '(' + (job.taxons.map { |taxon| "organism:#{ taxon }" } << 'organism:9606').join('+OR+') + ')'
        query += '+AND+(' + job.proteins.map { |protein| "gene:#{ protein.name }" }.join('+OR+') + ')'
        query
      end

      def build_uniprot_uri(query)
        # Create the base query.
        params = @helper.config[:uniprot][:parameters].merge(
          { @helper.config[:uniprot][:parameter_query] => query }
        )
        uri = URI::HTTP.build(
          host: @helper.config[:uniprot][:url],
          path: @helper.config[:uniprot][:entry_path],
          query: params.map{ |k,v| "#{ k }=#{ v }" }.join('&')
        )
        uri
      end

      def build_uniprot_queries(job, limit = nil)
        queries = []
        unless limit
          queries << build_uniprot_query(job)
        else
          queries = []
          species = '(' + (job.taxons.map { |taxon| "organism:#{ taxon }" } << 'organism:9606').join('+OR+') + ')'
          job.proteins.each_slice(limit) do |slice|
            queries << species + '+AND+(' + slice.map { |protein| "gene:#{ protein.name }" }.join('+OR+') + ')'
          end
        end
        queries
      end

      def build_protein_list!(job)
        job.genes.each do |gene|
          gene.transcripts.each do |trans_id, trans|
            p = trans.own_protein
            if p
              p.taxon = gene.taxon
              job.proteins << p
            end
            trans.proteins.each do |prot_name, prot|
              prot.taxon = gene.taxon
              job.proteins << prot
            end
          end
        end
      end

      def parse_uniprot_query!(response, uniprots = {})
        CSV.parse(response, headers: true, col_sep: "\t") do |row|
          uniprots[row['Organism ID']] ||= { rev: [], no_rev: [] }
          uniprots[row['Organism ID']][row['Status'] == 'reviewed' ? :rev : :no_rev] << {
            name: row['Gene names'].upcase.split(' ') ,
            id: row['Entry']
          }
        end
      end

      def parse_uniprot_response!(job, uniprots)
        # Build bind list (using human analogues).
        hsapiens = uniprots['9606']
        if hsapiens
          job.binds.each do |protein_name, bind|
            bind.protein_id = find_uniprot_id(hsapiens, protein_name)
          end
        end

        # Build the rest of the proteins.
        job.proteins.each do |protein|
          protein.protein_id = find_uniprot_id(uniprots[protein.taxon], protein.name)
          protein.protein_id ||= find_uniprot_id(uniprots['9606'], protein.name)
        end
      end

      def find_uniprot_id(results, protein)
        return nil unless results
        res = nil
        protein = protein.gsub('-', '')
        if results[:rev]
          uni = results[:rev].find { |x| x[:name].include?(protein) }
          res = uni[:id] if uni
        end
        if !res && results[:no_rev]
          uni = results[:no_rev].find { |x| x[:name].include?(protein) }
          res = uni[:id] if uni
        end
        return res
      end
    end
  end
end
