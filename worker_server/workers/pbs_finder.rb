require 'benchmark'
require 'json'
require 'yaml'
require 'uri'
require 'net/http'
require_relative 'pbs_finder/ensembl'
require_relative 'pbs_finder/ncbi'
require_relative 'pbs_finder/gene_container'
require_relative 'pbs_finder/helper'

class PbsFinder

  # Builds a new PBSFinder instance, loading its configurations from the given
  # file.
  def initialize
    @id = nil
    @helper = nil
    @job_id = nil
    @data = nil
  end

  def setup(id, helper, args)
    @id, @helper = id, helper
    @config = @helper.load_config('pbs_finder.yml')
    json = JSON.parse(args)
    @job_id = json['id']
    @data = json['data']
  end

  def work
    # Finding protein binding sites.
    begin
      helper = Pbs::Helper.new(@config)
      ensembl = Pbs::Ensembl.new(helper)
      ncbi = Pbs::Ncbi.new(helper)
      genes = nil
      bench = Benchmark.measure do
        genes = helper.divide_ids(@data, ncbi.process_ids(@data) + ensembl.process_ids(@data))
        ensembl.find_protein_binding_sites(genes[:ensembl])
        ncbi.find_protein_binding_sites(genes[:ncbi])
        genes = genes[:ensembl] + genes[:ncbi] + genes[:invalid]
      end
      time = bench.real < 0 ? 1 : bench.real.to_i

      # Save results to database.
      job = Job.find(@job_id)
      if job
        begin
          build_job_results(job, genes, time)
        rescue Exception => e
          puts e.message, e.backtrace
        end
      end

      # Notify master.
      @helper.notify_finish(@id, 'PBSFinder')
    rescue Exception => e
      puts e.message, e.backtrace
      @helper.notify_finish(@id, 'PBSFinder (error)')
      return
    end
  end

  private
  def build_job_results(job, genes, time)
    job.time = time
    bind_proteins = get_proteins(genes)
    build_genes(job, genes, bind_proteins)
    job.bind_proteins = bind_proteins
    job.completed = true
    job.save
  end

  def get_proteins(genes)
    hash = {}
    genes.each do |gene|
      (gene.transcripts || []).each do |trans, v1|
        next unless v1
        (v1[:proteins] || []).each do |protein, v2|
          if protein
            hash[protein] = (hash[protein] || 0) + 1
          end
        end
      end
    end
    return hash
  end

  def build_genes(job, genes, bind)
    if genes && genes.size > 0
      found = false
      genes.each do |gene|
        g = Gene.new(
          :original_id => gene.original_id,
          :converted_id => gene.id,
          :name => gene.name,
          :species => gene.species
        )
        if gene.transcripts && gene.transcripts.size > 0
          build_transcripts(g, gene.transcripts, bind)
          found ||= g.transcripts.size > 0
        end
        job.genes << g
      end
      job.valid = found
    end
  end

  def build_transcripts(gene, transcripts, bind)
    transcripts.each do |trans, values|
      t = Transcript.new(
        :converted_id => trans,
        :name => values[:name],
        :utr5 => values[:utr5],
        :utr3 => values[:utr3],
        :downstream => values[:downstream]
      )
      build_proteins(t, values[:proteins], bind)
      gene.binds ||= t.proteins.size > 0
      gene.transcripts << t
    end
  end

  def build_proteins(trans, proteins, bind)
    if proteins && proteins.size > 0
      set = Set.new
      proteins.each do |protein, values|
        p = Protein.new(:name => protein)
        values.each do |pos|
          p.positions << Position.new(
            :seq_start => pos[:start],
            :seq_end => pos[:end],
            :score => pos[:score],
            :sequence => pos[:seq]
          )
        end
        trans.proteins << p
        set.add(protein)
      end
      res = []
      bind.each do |prot, v|
        res << set.include?(prot)
      end
      trans.matches = res
    else
      trans.matches = Array.new(bind.size, false)
    end
  end

end
