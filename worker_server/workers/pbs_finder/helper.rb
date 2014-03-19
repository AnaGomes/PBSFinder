require 'nokogiri'

module Pbs
  class Helper

    ############################################################################
    # PUBLIC METHODS
    ############################################################################

    attr_reader :config
    def initialize(config = {})
      @config = config
    end

    # Returns a list of protein binding sites for a given nucleotide sequence.
    #
    # Input:
    #   - fasta: nucleotide sequence in fasta format
    # Output:
    #   - hash with protein names as keys and arrays of protein stats as values.
    def fetch_protein_binding_sites(fasta)
      proteins = {}
      uri = URI(@config[:rbpdb][:url] + @config[:rbpdb][:pbs_path])
      res = Net::HTTP.post_form(
        uri,
        'thresh' => 0.8,
        'seq'   => fasta
      )
      page = Nokogiri::HTML(res.body)
      page.css('table.pme-main tr.pme-row-0, table.pme-main tr.pme-row-1').each do |row|
        score = row.children[1].text[0...-1].to_i
        prot = row.children[2].children[0].text
        s_start = row.children[3].text.to_i
        s_end = row.children[4].text.to_i
        seq = row.children[5].text
        res = {}
        res[:score] = score
        res[:start] = s_start
        res[:end] = s_end
        res[:seq] = seq
        proteins[prot] ||= []
        proteins[prot] << res
      end
      return proteins
    end

    # Converts a list of IDs from "input" format to "output" format(s).
    #
    # Input:
    #   - list: array of IDs
    #   - input: input format
    #   - output: array of output formats
    # Output:
    #   - hash with original IDs as keys, and arrays of converted IDs as values.
    def convert_ids(list, input, output)
      ids = fetch_conversion_job(create_conversion_job(list, input, output)).split("\n")
      result = {}
      ids.drop(1).each do |id|
        id = id.split("\t")
        result[id[0]] = id[1].split(";").map(&:strip).map { |x| x =~ /^-$/ ? nil : x }
      end
      return result
    end

    # Divides the ID list into multiple types. Prelimarily filters invalid IDs.
    #
    # Input:
    #   - ids: array of IDs
    #   - genes: array of pre processed genes
    # Output:
    #   - hash with keys for each type and arrays of gene objects as values
    def divide_ids(ids, genes)
      result = {}
      result[:ensembl] = genes.select { |gene| gene.type == :ensembl && gene.id }
      result[:ncbi] = genes.select { |gene| gene.type == :ncbi && gene.id }
      result[:invalid] = []
      ids.each do |id|
        unless genes.find_index { |gene| gene.original_id == id && gene.id }
          result[:invalid] << Gene.new(id)
        end
      end
      return result
    end

    # Consolidates all the job information into a JSON string, ready to send.
    #
    # Input:
    #   - genes: array of Gene objects
    # Output:
    #   - JSON string
    def consolidate_results(genes)
      result = {}
      genes.each do |gene|
        if gene.transcripts.nil? || gene.transcripts.size == 0
          result[gene.original_id] = {}
        else
          result[gene.original_id] = {
            name: gene.name,
            id: gene.id,
            species: gene.species,
            transcripts: gene.transcripts || []
          }
        end
      end
      return result
    end

    # Returns a list of protein that bind to the transcript, and their stats.
    #
    # Input:
    #   - fasta: nucleotide sequence in fasta format
    # Output:
    #   - hash with protein names as keys, and protein stats as values
    def find_transcript_pbs(fasta)
      proteins = {}
      uri = URI(@config[:rbpdb][:url] + @config[:rbpdb][:pbs_path])
      res = Net::HTTP.post_form(
        uri,
        'thresh' => 0.8,
        'seq'   => fasta
      )
      page = Nokogiri::HTML(res.body)
      page.css('table.pme-main tr.pme-row-0, table.pme-main tr.pme-row-1').each do |row|
        score = row.children[1].text[0...-1].to_i
        prot = row.children[2].children[0].text
        s_start = row.children[3].text.to_i
        s_end = row.children[4].text.to_i
        seq = row.children[5].text
        res = {}
        res[:score] = score
        res[:start] = s_start
        res[:end] = s_end
        res[:seq] = seq
        proteins[prot] ||= []
        proteins[prot] << res
      end
      return proteins
    end

    ############################################################################
    # PRIVATE METHODS
    ############################################################################
    private

    # Creates a new conversion job in biodbnet.
    def create_conversion_job(list, input, output)
      uri = URI(@config[:biodbnet][:url] + @config[:biodbnet][:conversion_path])
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
      return res.body[/\<input[^\>]*name=('|")dbResFile('|")[^\/\>]*\/>/][/value=('|").*('|")/][7...-1]
    end

    # Fetches the result of a conversion job from biodbnet.
    def fetch_conversion_job(job_id)
      uri = URI(@config[:biodbnet][:url] + @config[:biodbnet][:fetch_path])
      res = Net::HTTP.post_form(
        uri,
        'dbResFile'         => job_id
      )
      return res.body
    end

  end
end
