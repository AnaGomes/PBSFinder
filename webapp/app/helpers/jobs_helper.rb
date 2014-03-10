# Helper methods defined here can be accessed in any controller or view in the application

require 'drb'
require 'set'

PbsSite::App.helpers do

  def prepare_ids(ids)
    ids.split("\n").collect(&:strip).reject { |x| x.empty? }
  end

  def long_job(job, url, data)
    remote = DRbObject.new_with_uri(settings.worker_server)
    json = { :url => url, :data => data }.to_json
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

  def get_proteins(job)
    set = Set.new
    job.genes.each do |gene|
      gene.transcripts.each do |trans|
        trans.proteins.each do |protein|
          set.add(protein.name)
        end
      end
    end
    return set
  end

  def build_job_results(job, json)
    if json['species']
      job.species = json['species'].split("_").each_with_index.map { |x, i| i == 0 ? x.capitalize : x }.join(" ")
      job.time = json['time']
      _build_genes(job, json)
    end
    job.completed = true
  end

  private
  def _build_genes(job, json)
    if json['genes']
      json['genes'].each do |gene, values|
        if values
          g = Gene.new(:ensembl_id => gene, :name => values['name'])
          _build_transcripts(g, values)
          job.genes << g
        else
          job.genes << Gene.new(:ensembl_id => gene)
        end
      end
    end
  end

  def _build_transcripts(gene, json)
    if json['transcripts']
      json['transcripts'].each do |trans, values|
        t = Transcript.new(
          :ensembl_id => trans,
          :name => values['name'],
          :utr5 => values['utr5'],
          :utr3 => values['utr3']
        )
        _build_proteins(t, values)
        gene.transcripts << t
      end
    end
  end

  def _build_proteins(trans, json)
    if json['proteins']
      json['proteins'].each do |protein, values|
        p = Protein.new(:name => protein)
        values.each do |pos|
          p.positions << Position.new(
            :seq_start => pos['start'],
            :seq_end => pos['end'],
            :score => pos['score'],
            :sequence => pos['seq']
          )
        end
        trans.proteins << p
      end
    end
  end

end
