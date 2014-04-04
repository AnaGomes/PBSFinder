require 'json'
require 'biomart'
require_relative 'gene'
require_relative 'custom_dataset'

module Pbs
  class Ensembl

    ############################################################################
    # PUBLIC METHODS
    ############################################################################

    def initialize(helper = nil)
      @helper = helper
    end

    # Processes a list of IDs and tries to identify/convert them.
    #
    # Input:
    #   - ids: array of strings (IDs)
    # Output:
    #   - array of Gene objects
    def process_ids(ids)
      return identify_ensembl_genes(ids) + identify_ensembl_trascripts(ids)
    end

    # Finds protein binding sites for a list of genes.
    #
    # Input:
    #   - array of Gene objects
    # Output:
    #   - array of Gene objects
    def find_protein_binding_sites(genes)
      if genes && genes.size > 0
        # Divide by species.
        species = Hash[genes.map { |gene| [gene.species, nil] }]
        species.keys.each { |spec| species[spec] = genes.select { |gene| gene.species == spec } }

        # Find transcripts for each species and their respective UTRs.
        species.each do |spec, ids|
          # Transcripts.
          dataset = species_to_dataset(spec)
          transcript_ids = []
          transcripts = find_transcript_ids(ids.map { |gene| gene.id }, dataset)[:data]
          ids.each do |gene|
            transcripts.each do |trans|
              if trans[0] == gene.id
                gene.name = trans[1]
                gene.transcripts ||= {}
                gene.transcripts[trans[2]] = { name: trans[3] }
                transcript_ids << trans[2]
              end
            end
          end

          # UTRs.
          begin
          utr5 = find_transcript_utr(transcript_ids, dataset, @helper.config[:ensembl_biomart][:attributes][:utr5])[:data]
          utr3 = find_transcript_utr(transcript_ids, dataset, @helper.config[:ensembl_biomart][:attributes][:utr3])[:data]
          downstream = find_transcript_downstream(transcript_ids, dataset)[:data]
          build_fasta_sequences(ids, utr5, :utr5)
          build_fasta_sequences(ids, utr3, :utr3)
          build_fasta_sequences(ids, downstream, :downstream)
          rescue Exception => e
            puts e.message, e.backtrace
          end
        end

        # Find protein binding sites.
        genes.each do |gene|
          if gene.transcripts
            gene.transcripts.each do |trans, values|
              fasta = values[:utr3] && values[:utr3].size >= 300 ? values[:utr3] : values[:downstream]
              values[:proteins] = @helper.find_transcript_pbs(fasta) if fasta
            end
          end
        end
      end
      return genes
    end

    ############################################################################
    # PRIVATE METHODS
    ############################################################################
    private

    def build_fasta_sequences(genes, sequences, key)
      sequences.each do |fasta|
        gene = genes.find { |g| g.id == fasta[1] }
        gene.transcripts[fasta[2]][key] = (fasta[0] =~ /unavailable/ ? nil : fasta[0].upcase) if gene
      end
    end

    def find_transcript_utr(ids, dt, utr)
      biomart = Biomart::Server.new(@helper.config[:ensembl_biomart][:url])
      dataset = biomart.datasets[dt]
      transcripts = dataset.search(
        filters: {
          @helper.config[:ensembl_biomart][:attributes][:entid] => ids.join(",")
        },
        attributes: [
          @helper.config[:ensembl_biomart][:attributes][:engid],
          @helper.config[:ensembl_biomart][:attributes][:entid],
          utr
        ]
      )
      return transcripts
    end

    def find_transcript_downstream(ids, dt)
      begin
        biomart = Biomart::Server.new(@helper.config[:ensembl_biomart][:url])
        dataset = biomart.datasets[dt]
        transcripts = dataset.search(
          filters: {
            @helper.config[:ensembl_biomart][:attributes][:downf] => "1000",
            @helper.config[:ensembl_biomart][:attributes][:entid] => ids.join(",")
          },
          attributes: [
            @helper.config[:ensembl_biomart][:attributes][:engid],
            @helper.config[:ensembl_biomart][:attributes][:entid],
            @helper.config[:ensembl_biomart][:attributes][:cflak]
          ]
        )
        return transcripts
      rescue
        return { data: [] }
      end
    end

    def find_transcript_ids(ids, dt)
      biomart = Biomart::Server.new(@helper.config[:ensembl_biomart][:url])
      dataset = biomart.datasets[dt]
      transcripts = dataset.search(
        filters: {
          @helper.config[:ensembl_biomart][:attributes][:engid] => ids.join(",")
        },
        attributes: [
          @helper.config[:ensembl_biomart][:attributes][:engid],
          @helper.config[:ensembl_biomart][:attributes][:engna],
          @helper.config[:ensembl_biomart][:attributes][:entid],
          @helper.config[:ensembl_biomart][:attributes][:entna]
        ]
      )
      return transcripts
    end

    def species_to_dataset(species)
      frags = species.downcase.split(' ')
      return "#{frags[0][0]}#{frags[1]}_gene_ensembl"
    end

    def identify_ensembl_genes(ids)
      species = @helper.config[:species].keys
      genes = []
      ids.each do |id|
        species.each do |s|
          if id =~ (s =~ /^FB$/ ? /^#{s}gn[0-9]{7}$/ : /^#{s}G[0-9]{11}$/)
            g = Gene.new id
            g.id = id
            g.type = :ensembl
            g.species = @helper.config[:species][s]
            genes << g
          end
        end
      end
      return genes
    end

    def identify_ensembl_trascripts(ids)
      species = @helper.config[:species].keys
      genes = []
      to_convert = []

      # Find transcript IDs.
      ids.each do |id|
        species.each do |s|
          if id =~ (s =~ /^FB$/ ? /^#{s}tr[0-9]{7}$/ : /^#{s}T[0-9]{11}$/)
            to_convert << id
            g = Gene.new id
            g.type = :ensembl
            g.species = @helper.config[:species][s]
            genes << g
          end
        end
      end

      # Convert transcript IDs.
      to_convert = @helper.convert_ids(to_convert, @helper.config[:formats][:entid], [ @helper.config[:formats][:engid] ])
      genes.each do |gene|
        gene.id = to_convert[gene.original_id].first
      end
      return genes
    end

  end
end
