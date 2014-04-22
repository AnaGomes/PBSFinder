module Pbs
  # Manages the ID analysis' workflow.
  class Workflow
    attr_accessor :job

    def initialize(config, ids, job_id)
      @job_id = job_id
      @helper = Analyzer::Helper.new(config)
      @ncbi = Analyzer::Ncbi.new(@helper)
      @ensembl = Analyzer::Ensembl.new(@helper)
      @ids = prepare_ids(ids)
      @job = Container::Job.new
    end

    def save_job_analysis
      Database.save_job_analysis(@job, @job_id)
    end

    def start_job_analysis
      return @job unless @ids.size > 0

      # Benchmark analysis.
      bench = Benchmark.realtime do

        # Base analysis.
        start_base_analysis
        break unless @job.genes.size > 0
        start_base_dataset_analysis

        # TODO ADVANCED ANALYSIS

        # Final stage.
        Analyzer::Dataset.create_invalid_genes!(@job, @ids)
      end
      if bench
        job.time = bench < 1 ? 1 : bench.to_i
      end
      @job
    end

    private

    def start_base_dataset_analysis
      Analyzer::Dataset.build_lists!(@job)
      Analyzer::Dataset.build_matches!(@job)
    end

    def start_base_analysis
      # Identify genes.
      genes = @ensembl.process_ids(@ids).concat(@ncbi.process_ids(@ids))
      genes = Analyzer::Dataset.divide_genes(genes)

      # Find gene transcripts.
      @ncbi.find_protein_binding_sites!(genes[:ncbi])
      @ensembl.find_protein_binding_sites!(genes[:ensembl])

      # Find protein binding sites.
      genes = genes[:ncbi].concat(genes[:ensembl])
      genes.select! { |x| x.gene_id && x.transcripts.size > 0 }
      @helper.find_protein_binding_sites!(genes)
      @job.genes = genes
    end

    def prepare_ids(ids)
      ids = ids.split("\n").map! { |x| x.strip.upcase }
      ids.reject! { |x| x.empty? }
      ids.uniq!
      ids
    end
  end
end
