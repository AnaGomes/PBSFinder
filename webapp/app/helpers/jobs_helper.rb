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
