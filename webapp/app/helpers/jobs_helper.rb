# Helper methods defined here can be accessed in any controller or view in the application

require 'drb'
require 'set'

PbsSite::App.helpers do

  def prepare_ids(ids)
    ids.split("\n").map(&:strip).map(&:upcase).reject { |x| x.empty? }.uniq
  end

  def gene_link(id, type, name, species, text = nil)
    complete = text || (name ? "#{id} (#{name})" : id)
    species = species.split(' ').first(2).join('_').capitalize
    case type
    when :ncbi
      return "<a href=\"http://www.ncbi.nlm.nih.gov/gene/#{id}\">#{complete}</a>"
    when :ensembl
      if id =~ /^ENS(G|T)[0-9]+$/
        return "<a href=\"http://www.ensembl.org/Homo_sapiens/Gene/Summary?db=core;g=#{id}\">#{complete}</a>"
      else
        return "<a href=\"http://www.ensembl.org/#{species}/Gene/Summary?db=core;g=#{id}\">#{complete}</a>"
      end
    when :uniprot
      return "<a href=\"http://www.uniprot.org/uniprot/#{id}\">#{complete}</a>"
    when :stringdb
      return "<a href=\"http://string-db.org/newstring_cgi/show_network_section.pl?identifier=#{id}\">#{complete}</a>"
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
    return true
  end

  def format_fasta(fasta, max = 80)
    fasta.scan(/.{1,#{max}}/)
  end

end
