module Pbs
  module Analyzer
    # Analyzes Ensembl IDs and retrieves basic information about them.
    class Ensembl
      def initialize(helper = nil)
        @helper = helper
      end

      # Processes a list of IDs and tries to identify/convert them.
      #
      # Input:
      #   - ids: array of strings (IDs)
      # Output:
      #   - array of GeneContainer objects
      def process_ids(ids)
        genes = identify_ensembl_genes(ids) + identify_ensembl_trascripts(ids)
        genes.reject! { |g| !g.gene_id }
        genes
      end

      # Finds protein binding sites for a list of genes.
      #
      # Input:
      #   - array of GeneContainer objects
      # Output:
      #   - array of GeneContainer objects
      def find_protein_binding_sites!(genes)
        if genes && genes.size > 0
          find_transcripts(genes)
        end
        genes
      end

      private

      def find_transcripts(genes)
        species = Hash[genes.map { |gene| [gene.species, nil] }]
        species.keys.each { |spec| species[spec] = genes.select { |gene| gene.species == spec } }

        # Find transcripts for each species and their respective UTRs.
        species.each do |spec, ids|
          # Transcripts.
          dataset = species_to_dataset(spec)
          transcript_ids = []
          transcripts = find_transcript_ids(ids.map { |gene| gene.gene_id }, dataset)[:data]
          ids.each do |gene|
            transcripts.each do |trans|
              if trans[0].upcase == gene.gene_id
                gene.name = trans[1]
                gene.transcripts[trans[2]] = Container::Transcript.new(
                  name: trans[3],
                  transcript_id: trans[2].upcase
                )
                transcript_ids << trans[2].upcase
              end
            end
          end

          # UTRs.
          next unless transcript_ids.size > 0
          begin
            utr5 = find_transcript_utr(transcript_ids, dataset, @helper.config[:ensembl_biomart][:attributes][:utr5])[:data]
            utr3 = find_transcript_utr(transcript_ids, dataset, @helper.config[:ensembl_biomart][:attributes][:utr3])[:data]
            downstream = find_transcript_downstream(transcript_ids, dataset)[:data]
            build_fasta_sequences(ids, utr5, :utr5)
            build_fasta_sequences(ids, utr3, :utr3)
            build_fasta_sequences(ids, downstream, :downstream)
          rescue StandardError => e
            puts e.message, e.backtrace
          end
        end
      end

      def build_fasta_sequences(genes, sequences, key)
        sequences.each do |fasta|
          gene = genes.find { |g| g.gene_id == fasta[1] }
          if gene
            seq = fasta[0] =~ /unavailable/ ? nil : fasta[0].upcase
            case key
            when :utr5
              gene.transcripts[fasta[2]].utr5 = seq
            when :utr3
              gene.transcripts[fasta[2]].utr3 = seq
            when :downstream
              gene.transcripts[fasta[2]].downstream = seq
            end
          end
        end
      end

      def find_transcript_utr(ids, dt, utr)
        transcripts = nil
        begin
          biomart = Biomart::Server.new(@helper.config[:ensembl_biomart][:url])
          dataset = biomart.datasets[dt]
          transcripts = dataset.search(
            filters: {
              @helper.config[:ensembl_biomart][:attributes][:entid] => ids.join(',')
            },
            attributes: [
              @helper.config[:ensembl_biomart][:attributes][:engid],
              @helper.config[:ensembl_biomart][:attributes][:entid],
              utr
            ]
          )
        rescue Biomart::BiomartError => e
          puts e.message, e.backtrace
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end
        transcripts
      end

      def find_transcript_downstream(ids, dt)
        transcripts = nil
        begin
          biomart = Biomart::Server.new(@helper.config[:ensembl_biomart][:url])
          dataset = biomart.datasets[dt]
          transcripts = dataset.search(
            filters: {
              @helper.config[:ensembl_biomart][:attributes][:downf] => '1000',
              @helper.config[:ensembl_biomart][:attributes][:entid] => ids.join(',')
            },
            attributes: [
              @helper.config[:ensembl_biomart][:attributes][:engid],
              @helper.config[:ensembl_biomart][:attributes][:entid],
              @helper.config[:ensembl_biomart][:attributes][:cflak]
            ]
          )
        rescue Biomart::BiomartError => e
          puts e.message, e.backtrace
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end
        transcripts
      end

      def find_transcript_ids(ids, dt)
        transcripts = nil
        begin
          biomart = Biomart::Server.new(@helper.config[:ensembl_biomart][:url])
          dataset = biomart.datasets[dt]
          transcripts = dataset.search(
            filters: {
              @helper.config[:ensembl_biomart][:attributes][:engid] => ids.join(',')
            },
            attributes: [
              @helper.config[:ensembl_biomart][:attributes][:engid],
              @helper.config[:ensembl_biomart][:attributes][:engna],
              @helper.config[:ensembl_biomart][:attributes][:entid],
              @helper.config[:ensembl_biomart][:attributes][:entna]
            ]
          )
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end
        transcripts
      end

      def species_to_dataset(species)
        frags = species.downcase.split(' ')
        "#{frags[0][0]}#{frags[1]}_gene_ensembl"
      end

      def identify_ensembl_genes(ids)
        species = @helper.config[:species].keys
        genes = []
        ids.each do |id|
          species.each do |s|
            if id =~ (s =~ /^FB$/ ? /^#{s}GN[0-9]{7}$/ : /^#{s}G[0-9]{11}$/)
              g = Container::Gene.new(
                original_id: id,
                gene_id: id,
                type: :ensembl,
                taxon: @helper.config[:species][s],
                species: @helper.config[:taxons][@helper.config[:species][s]]
              )
              genes << g
            end
          end
        end
        genes
      end

      def identify_ensembl_trascripts(ids)
        species = @helper.config[:species].keys
        genes = []
        to_convert = []

        # Find transcript IDs.
        ids.each do |id|
          species.each do |s|
            if id =~ (s =~ /^FB$/ ? /^#{s}TR[0-9]{7}$/ : /^#{s}T[0-9]{11}$/)
              to_convert << id
              g = Container::Gene.new(
                original_id: id,
                type: :ensembl,
                taxon: @helper.config[:species][s],
                species: @helper.config[:taxons][@helper.config[:species][s]]
              )
              genes << g
            end
          end
        end

        # Convert transcript IDs.
        to_convert = @helper.convert_ids(to_convert, @helper.config[:formats][:entid], [@helper.config[:formats][:engid]])
        genes.each do |gene|
          gene.gene_id = to_convert[gene.original_id].first
        end
        genes
      end
    end
  end
end
