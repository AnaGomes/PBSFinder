module Pbs
  # Manages database persitence.
  class Database
    def self.save_job_analysis(job, id)
      db = Job.find(id)
      save_job(job, db) if db && job
    rescue StandardError => e
      puts e.message, e.backtrace
    end

    def self.save_job(job, db)
      job.genes.each do |gene|
        g = Gene.new
        save_gene(gene, g)
        db.genes << g
      end
      save_cluster(job, db)
      save_extra(job, db)
      save_files(db)
      db.save
    end

    def self.save_cluster(job, db)
      job.cluster_info.each do |cls|
        cluster = Cluster.new(
          gene_clusters: cls.gene_clusters || {},
          protein_clusters: cls.clusters || {},
          gene_attrs: cls.gene_sims || {},
          protein_attrs: cls.protein_sims || {},
          type: cls.type || :by_function
        )
        db.clusters << cluster
      end
    end

    def self.save_files(db)
      if db.complete && db.time
        # Save files.
        grid_fs = Mongoid::GridFs
        rbp_csv = grid_fs.put(StringIO.new(db.to_csv, 'r'))
        rbp_tsv = grid_fs.put(StringIO.new(db.to_csv(col_sep: "\t"), 'r'))
        prot_csv = grid_fs.put(StringIO.new(db.to_prot_csv, 'r'))
        prot_tsv = grid_fs.put(StringIO.new(db.to_prot_csv(col_sep: "\t"), 'r'))
        prolog = grid_fs.put(StringIO.new(db.to_prolog, 'r'))

        # Save IDs.
        db.files[:rbp_csv] = rbp_csv.id
        db.files[:rbp_tsv] = rbp_tsv.id
        db.files[:prot_csv] = prot_csv.id
        db.files[:prot_tsv] = prot_tsv.id
        db.files[:prolog] = prolog.id
      end
    end

    def self.save_extra(job, db)
      job.binds.each do |k, bind|
        b = Bind.new(
          count: bind.count,
          name: bind.name,
          protein_id: bind.protein_id
        )
        db.binds << b
      end
      db.time = job.time
      db.complete = true
    end

    def self.save_gene(gene, db)
      db.query_id = gene.original_id
      db.gene_id = gene.gene_id
      db.name = gene.name
      db.species = gene.species
      db.taxon = gene.taxon
      db.id_type = gene.type
      db.binds = gene.binds
      gene.transcripts.each do |k, trans|
        t = Transcript.new
        save_transcript(trans, t)
        db.transcripts << t
      end
    end

    def self.save_transcript(trans, db)
      db.transcript_id = trans.transcript_id
      db.name = trans.name
      db.utr5 = trans.utr5
      db.utr3 = trans.utr3
      db.downstream = trans.downstream
      db.matches = trans.matches
      trans.proteins.each do |k, prot|
        p = Protein.new
        save_protein(prot, p)
        db.proteins << p
      end
      if trans.own_protein
        p = Protein.new
        save_protein(trans.own_protein, p)
        db.own_protein = p
      end
    end

    def self.save_protein(prot, db)
      db.protein_id = prot.protein_id
      db.species = prot.species
      db.name = prot.name
      db.external_ids = prot.external_ids
      db.tissues = prot.tissues
      db.keywords = prot.keywords
      db.biological_process = prot.biological_process
      db.cellular_component = prot.cellular_component
      db.molecular_function = prot.molecular_function
      db.pathways = prot.pathways
      prot.positions.each do |pos|
        db.positions << Position.new(
          seq_start: pos.start,
          seq_end: pos.end,
          score: pos.score,
          sequence: pos.seq
        )
      end
    end

    private_class_method(
      :save_cluster,
      :save_files,
      :save_job,
      :save_extra,
      :save_gene,
      :save_transcript,
      :save_protein,
      :new
    )
  end
end
