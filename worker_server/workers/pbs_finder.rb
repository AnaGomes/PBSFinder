require 'biomart'
require 'drb'
require 'json'
require 'yaml'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'net/http/post/multipart'

class PbsFinder

  # Builds a new PBSFinder instance, loading its configurations from the given
  # file.
  def initialize
    @id = nil
    @config = nil
    @notifier = nil
    @saver = nil
    @resp_url = nil
    @data = nil
    @token = nil
  end

  def setup(id, config, saver, notifier, args)
    @id, @saver, @notifier = id, saver, notifier
    @config = config.load_config('pbs_finder.yml')
    json = JSON.parse(args)
    @resp_url = json['url']
    @data = json['data']
  end

  def work
    resp = get_proteins(@data).to_json
    uri = URI(@resp_url)
    @saver.save_file(@id, resp)
    req = Net::HTTP::Post::Multipart.new uri.path,
      "result" => UploadIO.new(File.new(@saver.file_path(@id)), "application/json", "result.json")
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    @saver.delete_file(@id)
    @notifier.notify_finish(@id, 'pbs finder finished')
  end

  # Separates the given array of IDs in two groups, ENSEMBL and ENTREZ. The
  # result is a map of arrays containing the list of IDs of each type, with
  # keys :entrez and :ensembl.
  def identify_ids(ids)
    new_ids = { entrez: [], ensembl: [] }
    ids.each do |id|
      if id =~ /^EN/
        new_ids[:ensembl] << id
      else
        new_ids[:entrez] << id
      end
    end
    return new_ids
  end

  # Receives an array of ENTREZ IDs and converts them to ENSEMBL IDs, returning
  # a map of the old IDs and their conversion, if possible.
  def convert_ids(ids)
    job_id = _convert_ids(ids, @config[:formats][:ezgid], [ @config[:formats][:engid] ])
    new_ids = _fetch_ids(job_id)
    parsed = new_ids.split("\n")
    parsed.shift
    converted = {}
    parsed.each do |line|
      pair = line.split("\t")
      converted[pair[0]] = (pair[1] =~ /^-$/ ? nil : pair[1])
    end
    return converted
  end

  # Tries to identify a species, based on its genes' IDs. Returns a string
  # representation of the species' name.
  def identify_species(ids)
    species = nil
    ids.each do |id|
      species = _identify_species(id)
      break if species
    end
    return species
  end

  # Converts a species name to a valid Ensembl.org dataset name.
  def species_to_dataset(species)
    frags = species.downcase.split('_')
    return "#{frags[0][0]}#{frags[1]}_gene_ensembl"
  end

  # Gets the IDs of all transcripts associated with the genes in the array.
  # Returns a map from all the IDs to an array with their transcript IDs.
  def get_transcript_ids(ids, dt)
    biomart = Biomart::Server.new(@config[:ensembl_biomart][:url])
    dataset = biomart.datasets[dt]
    transcripts = dataset.search(
      filters: {
        @config[:ensembl_biomart][:attributes][:engid] => ids.join(",")
      },
      attributes: [
        @config[:ensembl_biomart][:attributes][:engid],
        @config[:ensembl_biomart][:attributes][:engna],
        @config[:ensembl_biomart][:attributes][:entid],
        @config[:ensembl_biomart][:attributes][:entna]
      ]
    )
    return transcripts
  end

  # Retrieves the 5' UTR FASTA sequences for the given transcript IDs.
  def get_transcript_utr(ids, dt, utr)
    biomart = Biomart::Server.new(@config[:ensembl_biomart][:url])
    dataset = biomart.datasets[dt]
    transcripts = dataset.search(
      filters: {
        @config[:ensembl_biomart][:attributes][:entid] => ids.join(",")
      },
      attributes: [
        @config[:ensembl_biomart][:attributes][:engid],
        @config[:ensembl_biomart][:attributes][:entid],
        utr
      ]
    )
    return transcripts
  end

  # Finds the list of proteins that bind with the given UTR FASTA sequences.
  def get_protein_binding_sites(data)
    data.each do |id, info|
      next unless info
      info[:transcripts].each do |tid, tinfo|
        tinfo[:proteins] = tinfo[:utr3] ? _fetch_pbs(tinfo[:utr3]) : nil
      end
    end
  end

  # Retrives the protein names for a given list of gene IDs.
  def get_proteins(ids)
    # Identify and convert IDs to Ensembl notation.
    identified = identify_ids(ids)
    converted = convert_ids(identified[:entrez])

    # Build results scaffold.
    result = {}
    identified[:ensembl].each do |id|
      result[id] = {}
    end
    converted.each do |k, v|
      if v
        result[v] = {}
      else
        result[k] = nil
      end
    end

    # Identify species and dataset.
    species = identify_species(result.keys)
    return result unless species
    dataset = species_to_dataset(species)
    return result unless dataset

    # Retrieve transcript IDs for each gene.
    transcript_ids = get_transcript_ids(result.keys, dataset)[:data]
    transcripts = []
    transcript_ids.each do |a|
      result[a[0]][:name] ||= a[1]
      result[a[0]][:transcripts] ||= {}
      result[a[0]][:transcripts][a[2]] = { name: a[3] }
      transcripts << a[2]
    end

    # Retrieve FASTA UTRs.
    utr5 = get_transcript_utr(transcripts, dataset, @config[:ensembl_biomart][:attributes][:utr5])[:data]
    utr3 = get_transcript_utr(transcripts, dataset, @config[:ensembl_biomart][:attributes][:utr3])[:data]
    utr5.each do |a|
      result[a[1]][:transcripts][a[2]][:utr5] = a[0] =~ /unavailable/ ? nil : a[0]
    end
    utr3.each do |a|
      result[a[1]][:transcripts][a[2]][:utr3] = a[0] =~ /unavailable/ ? nil : a[0]
    end

    # Retrieve protein binding sites.
    get_protein_binding_sites(result)

    # Result.
    res = { species: species }
    res[:genes] = result
    return res
  end

  private

  # Fetches the result of a conversion job fro biodbnet.
  def _fetch_ids(job_id)
    uri = URI(@config[:biodbnet][:url] + @config[:biodbnet][:fetch_path])
    res = Net::HTTP.post_form(
      uri,
      'dbResFile'         => job_id
    )
    return res.body
  end

  # Creates a new conversion job to biodbnet.
  def _convert_ids(list, input, output)
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

  def _fetch_pbs(fasta)
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
      seq = row.children[5].text.to_i
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

  # Identifies the species to which a specific ID belongs to.
  def _identify_species(id)
    uri = URI(@config[:ensembl_rest][:url] + @config[:ensembl_rest][:lookup_path] + "/#{id}")
    params = {
      'content-type' => 'text/json',
      'format' => 'condensed'
    }
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host)
    res = http.get(uri.request_uri, {'Content-Type' => 'application/json'})
    json = JSON.parse(res.body)
    return json['species']
  end

end
