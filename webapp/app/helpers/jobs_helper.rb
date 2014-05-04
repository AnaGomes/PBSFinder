# Helper methods defined here can be accessed in any controller or view in the application

require 'drb'
require 'set'

PbsSite::App.helpers do

  def gene_link(id, type, name, text = nil)
    complete = text || (name ? "#{ id } (#{ name })" : id)
    case type
    when :ncbi
      return "<a href=\"http://www.ncbi.nlm.nih.gov/gene/#{ id }\">#{ complete }</a>"
    when :ensembl
      return "<a href=\"http://www.ensembl.org/id/#{ id }\">#{ complete }</a>"
    when :uniprot
      return "<a href=\"http://www.uniprot.org/uniprot/#{ id }\">#{ complete }</a>"
    when :stringdb
      return "<a href=\"http://string-db.org/newstring_cgi/show_network_section.pl?identifier=#{ id }\">#{ complete }</a>"
    end
  end

  def external_link(type, values)
    name = ''
    link = ''
    case type
    when 'ensembl'
      name = 'Ensembl'
      link = values.map { |v| "<a href=\"http://www.ensembl.org/id/#{ v[1] }\">#{ v[1] }</a>" }.join(',  ')
    when 'geneid'
      name = 'Geneid'
      link = values.map { |v| "<a href=\"http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&term=#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    when 'string'
      name = 'Stringdb'
      link = values.map { |v| "<a href=\"http://string-db.org/newstring_cgi/show_network_section.pl?identifier=#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    when 'kegg'
      name = 'Kegg'
      link = values.map { |v| "<a href=\"http://www.genome.jp/dbget-bin/www_bget?#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    when 'ucsc'
      name = 'Ucsc'
      link = values.map { |v| "<a href=\"http://genome.ucsc.edu/cgi-bin/hgGene?hgg_gene=#{ v[0] }&org=#{ v[1] }\">#{ v[0] }</a>" }.join(',  ')
    when 'ko'
      name = 'Kegg ortho'
      link = values.map { |v| "<a href=\"\http://www.genome.jp/dbget-bin/www_bget?ko:#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    when 'gene3d'
      name = 'Gene3d'
      link = values.map { |v| "<a href=\"http://www.cathdb.info/superfamily/#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    when 'orthodb'
      name = 'Orthodb'
      link = values.map { |v| "<a href=\"http://cegg.unige.ch/orthodb/results?searchtext=#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    when 'phosphosite'
      name = 'Phosphosite'
      link = values.map { |v| "<a href=\"http://www.phosphosite.org/uniprotAccAction.do?id=#{ v[0] }\">#{ v[0] }</a>" }.join(',  ')
    else
      link = ""
    end
    unless link.empty?
      link = "<tr><td class=\"first\">#{ name }</td><td class=\"external\">" + link + "</td></tr>"
    end
    link
  end

  def transcript_link(id, type, name, text = nil)
    complete = text || (name ? "#{ id } (#{ name })" : id)
    case type
    when :ncbi
      return "<a href=\"http://www.ncbi.nlm.nih.gov/nuccore/#{ id }\">#{ complete }</a>"
    when :ensembl
      return "<a href=\"http://www.ensembl.org/id/#{ id }\">#{ complete }</a>"
    end
  end

  def long_job(job, id, url, data)
    remote = DRbObject.new_with_uri(settings.worker_server)
    json = { :id => id, :data => data, :url => url }.to_json
    remote.start_new_worker(job, json)
  end

  def server_running?
    begin
      remote = DRbObject.new_with_uri('druby://localhost:5555')
      remote.working?
    rescue
      return false
    end
    true
  end

  def format_fasta(fasta, max = 80)
    fasta.scan(/.{1,#{max}}/)
  end

end
