module Pbs
  module Analyzer
    # Manipulates gene datasets and aggregates information.
    class Dataset
      private_class_method :new

      # Divides the ID list into multiple types. Prelimarily filters invalid IDs.
      #
      # Input:
      #   - ids: array of IDs
      #   - genes: array of pre processed genes
      # Output:
      #   - hash with keys for each type and arrays of gene objects as values
      def self.divide_genes(genes)
        result = {}
        genes.uniq! { |gene| gene.gene_id }
        result[:ensembl] = genes.select { |gene| gene.type == :ensembl && gene.gene_id }
        result[:ncbi] = genes.select { |gene| gene.type == :ncbi && gene.gene_id }
        result
      end

      def self.create_invalid_genes!(job, ids)
        set = Set.new
        job.genes.each { |g| set.add(g.original_id) }
        ids.each do |id|
          unless set.include?(id)
            job.genes << Container::Gene.new(original_id: id)
          end
        end
      end

      def self.build_own_proteins!(job)
        job.genes.each do |gene|
          gene.transcripts.each do |trans_id, trans|
            if gene.name
              trans.own_protein = Container::Protein.new(name: gene.name)
            end
          end
        end
      end

      def self.build_lists!(job)
        job.genes.each do |gene|
          job.species.add(gene.species)
          job.taxons.add(gene.taxon)
          gene.transcripts.each do |trans_id, trans|
            trans.proteins.each do |prot_name, prot|
              gene.binds ||= true
              job.binds[prot_name] ||= Container::Bind.new(name: prot_name)
              job.binds[prot_name].count += 1
            end
          end
        end
      end

      def self.build_matches!(job)
        job.genes.each do |gene|
          gene.transcripts.each do |trans_id, trans|
            trans.matches = job.binds.map { |bind, v| trans.proteins.include?(bind) }
          end
        end
      end
    end
  end
end
