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
      save_extra(job, db)
      db.save
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
    end

    def self.save_protein(prot, db)
      db.protein_id = prot.protein_id
      db.name = prot.name
      db.external_ids = prot.external_ids
      db.tissues = prot.tissues
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
      :save_job,
      :save_extra,
      :save_gene,
      :save_transcript,
      :save_protein,
      :new
    )
  end
end
