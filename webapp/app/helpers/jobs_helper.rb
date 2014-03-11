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

  def format_fasta(fasta, max = 80)
    fasta.scan(/.{1,#{max}}/)
  end

  def build_job_results(job, json)
    if json['species']
      job.species = json['species'].split("_").each_with_index.map { |x, i| i == 0 ? x.capitalize : x }.join(" ")
      job.time = json['time']
      bind_proteins = _get_proteins(json)
      _build_genes(job, json, bind_proteins)
      job.bind_proteins = bind_proteins
    end
    job.completed = true
  end

  private
  def _get_proteins(json)
    set = Set.new
    (json['genes'] || []).each do |k1, gene|
      next unless gene
      (gene['transcripts'] || []).each do |k2, trans|
        next unless trans
        (trans['proteins'] || []).each do |protein, v1|
          if protein
            set.add(protein)
          end
        end
      end
    end
    set.to_a
  end

  def _build_genes(job, json, bind)
    if json['genes']
      json['genes'].each do |gene, values|
        if values
          g = Gene.new(:ensembl_id => gene, :name => values['name'])
          _build_transcripts(g, values, bind)
          job.genes << g
        else
          job.genes << Gene.new(:ensembl_id => gene)
        end
      end
    end
  end

  def _build_transcripts(gene, json, bind)
    if json['transcripts']
      json['transcripts'].each do |trans, values|
        t = Transcript.new(
          :ensembl_id => trans,
          :name => values['name'],
          :utr5 => values['utr5'],
          :utr3 => values['utr3']
        )
        _build_proteins(t, values, bind)
        gene.binds ||= t.proteins.size > 0
        gene.transcripts << t
      end
    end
  end

  def _build_proteins(trans, json, bind)
    if json['proteins']
      set = Set.new
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
        set.add(protein)
      end
      res = []
      bind.each do |prot|
        res << set.include?(prot)
      end
      trans.matches = res
    else
      trans.matches = Array.new(bind.size, false)
    end
  end

end
