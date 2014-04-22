module Pbs
  module Analyzer
    # Provides functionalities that are horizontal to the analyzers.
    class Helper
      attr_reader :config

      def initialize(config = {})
        @config = config
      end

      # Converts a list of IDs from "input" format to "output" format(s).
      #
      # Input:
      #   - list: array of IDs
      #   - input: input format
      #   - output: array of output formats
      # Output:
      #   - hash with original IDs as keys, and arrays of converted IDs as
      #   values.
      def convert_ids(list, input, output)
        begin
          ids = fetch_conversion_job(create_conversion_job(list, input, output))
          ids = ids.split("\n")
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end
        result = {}
        ids.drop(1).each do |id|
          id = id.split("\t")
          id.drop(1).each do |i|
            result[id[0]] ||= []
            result[id[0]] += i.split(';').map(&:strip).map { |x| (x.empty? || x =~ /^-$/) ? nil : x.upcase }
          end
        end
        result
      end

      # Finds protein binding sites for a list of genes.
      #
      # Input:
      #   - array of GeneContainer objects
      # Output:
      #   - array of GeneContainer objects
      def find_protein_binding_sites!(genes)
        if genes && genes.size > 0
          genes.each do |gene|
            gene.transcripts.each do |trans_id, trans|
              fasta = nil
              if trans.utr3 && trans.utr3.size >= 300
                fasta = trans.utr3
              elsif trans.downstream
                fasta = trans.downstream
              else
                fasta = trans.utr3
              end
              trans.proteins = find_transcript_pbs(fasta) if fasta
            end
          end
        end
        genes
      end

      def determine_ensembl_species!(genes)
        species = @config[:species].keys
        genes.each do |gene|
          species.each do |s|
            if gene.gene_id =~ (s =~ /^FB$/ ? /^#{s}gn[0-9]{7}$/ : /^#{s}G[0-9]{11}$/)
              gene.type = :ensembl
              gene.taxon = @config[:species][s]
              gene.species = @config[:taxons][gene.taxon]
            end
          end
        end
        genes
      end

      private

      # Returns a list of protein that bind to the transcript, and their stats.
      #
      # Input:
      #   - fasta: nucleotide sequence in fasta format
      # Output:
      #   - hash with protein names as keys, and protein stats as values
      def find_transcript_pbs(fasta)
        proteins = {}
        fasta = (fasta || '').gsub(/(n|N)/, '')
        unless fasta.empty?
          begin
            uri = URI(@config[:rbpdb][:url] + @config[:rbpdb][:pbs_path])
            res = Net::HTTP.post_form(
              uri,
              'thresh' => 0.8,
              'seq'   => fasta
            )
            page = Nokogiri::HTML(res.body)
            page.css('table.pme-main tr.pme-row-0, table.pme-main tr.pme-row-1').each do |row|
              # Fetch base data.
              pos = Container::Position.new(
                score: row.children[1].text[0...-1].to_i,
                start: row.children[3].text.to_i,
                end: row.children[4].text.to_i,
                seq: row.children[5].text
              )

              # Fetch protein name and build result structure.
              prot = row.children[2].children[0].text.upcase
              proteins[prot] ||= Container::Protein.new(name: prot)
              proteins[prot].positions << pos
            end
          rescue StandardError => e
            puts e.message, e.backtrace
            retry
          end
        end
        proteins
      end

      # Creates a new conversion job in biodbnet.
      def create_conversion_job(list, input, output)
        uri = URI(
          @config[:biodbnet][:url] + @config[:biodbnet][:conversion_path]
        )
        res = Net::HTTP.post_form(
          uri,
          'taxonId'           => 'optional',
          'hasComma'          => 'no',
          'removeDupValues'   => 'yes',
          'request'           => 'db2db',
          'input'             => input,
          'outputs[]'         => output,
          'idList'            => list.join("\n")
        )
        res.body[%r{<input[^>]*name=('|")dbResFile('|")[^/>]*/>}][/value=('|").*('|")/][7...-1]
      end

      # Fetches the result of a conversion job from biodbnet.
      def fetch_conversion_job(job_id)
        uri = URI(@config[:biodbnet][:url] + @config[:biodbnet][:fetch_path])
        res = Net::HTTP.post_form(
          uri,
          'dbResFile' => job_id
        )
        res.body
      end
    end
  end
end
