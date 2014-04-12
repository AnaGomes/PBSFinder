# Helper methods defined here can be accessed in any controller or view in the application

require 'drb'
require 'set'

PbsSite::App.helpers do

  def prepare_ids(ids)
    ids.split("\n").collect(&:strip).reject { |x| x.empty? }.uniq
  end

  def gene_link(id, type, name, species)
    complete = name ? "#{id} (#{name})" : id
    species = species.split(' ').first(2).join('_').capitalize
    if type == :ncbi
      return "<a href=\"http://www.ncbi.nlm.nih.gov/gene/#{id}\">#{complete}</a>"
    elsif type == :ensembl
      return "<a href=\"http://www.ensembl.org/#{species}/Gene/Summary?db=core;g=#{id}\">#{complete}</a>"
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
