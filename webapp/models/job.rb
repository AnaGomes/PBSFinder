require 'csv'
require 'set'

class Job
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to  :account,   index: true
  embeds_many :binds,     cascade_callbacks: true
  embeds_many :clusters,  cascade_callbacks: true
  has_many    :genes,     dependent: :delete, autosave: true

  before_destroy :destroy_files

  attr_accessor :query

  field :complete,      type: Boolean, default: false
  field :description,   type: String
  field :notify,        type: Boolean, default: false
  field :time,          type: Integer
  field :files,         type: Hash, default: {}

  validates_presence_of :query, :if => :query_required
  validates_presence_of :complete
  validates_presence_of :notify
  validates_presence_of :description
  validates_length_of   :description, :within => 5..256

  index({ created_at: 1 }, { background: false })

  def self.find_by_id(id)
    find(id) rescue nil
  end

  def to_csv(options = {})
    CSV.generate(options) do |csv|
      header = %w[species gene_id gene_name transcript_id transcript_name]
      header += self.binds.map { |bind| bind.name }
      csv << header
      genes.each do |gene|
        gene.transcripts.each do |trans|
          line = [gene.species, gene.gene_id, gene.name, trans.transcript_id, trans.name]
          line += trans.matches.map { |x| x ? 'x' : '' }
          csv << line
        end
      end
    end
  end

  def to_prot_csv(options = {})
    CSV.generate(options) do |csv|
      header = %w[gene_species gene_id gene_name transcript_id transcript_name]
      header += %w[protein_species protein_id protein_name own keywords]
      header += %w[tissues molecular_function cellular_component biological_process pathways]
      csv << header
      genes.each do |gene|
        gene.transcripts.each do |trans|
          line = [gene.species, gene.gene_id, gene.name, trans.transcript_id, trans.name]
          trans.proteins.each do |prot|
            line2 = [prot.species, prot.protein_id, prot.name, false]
            line2 += [
              prot.keywords.map(&:downcase).join(';'),
              prot.tissues.map(&:downcase).join(';'),
              prot.molecular_function.map(&:downcase).join(';'),
              prot.cellular_component.map(&:downcase).join(';'),
              prot.biological_process.map(&:downcase).join(';'),
              prot.pathways.map { |k, name| name.downcase }.join(';')
            ]
            csv << line + line2
          end
          if trans.own_protein
            prot = trans.own_protein
            line2 = [prot.species, prot.protein_id, prot.name, true]
            line2 += [
              prot.keywords.map(&:downcase).join(';'),
              prot.tissues.map(&:downcase).join(';'),
              prot.molecular_function.map(&:downcase).join(';'),
              prot.cellular_component.map(&:downcase).join(';'),
              prot.biological_process.map(&:downcase).join(';'),
              prot.pathways.map { |k, name| name.downcase }.join(';')
            ]
            csv << line + line2
          end
        end
      end
    end
  end

  def to_prolog
    parts = init_prolog_hash
    prots = {}
    genes.each do |gene|
      # Gene info.
      if gene.transcripts.size > 0
        parts[:gene_id] << "gene(gene_#{ gene.id }).\n"
        parts[:gene_name] << "/* gene_name(gene_#{ gene.id }, '#{ gene.name.downcase }'). */\n" if gene.name
        parts[:gene_species] << "gene_species(gene_#{ gene.id }, '#{ gene.species.downcase }').\n" if gene.species

        # Transcript info.
        gene.transcripts.each do |tran|
          parts[:gene_tran] << "gene_transcript(gene_#{ gene.id }, tran_#{ tran.id }).\n"
          parts[:tran_id] << "transcript(tran_#{ tran.id }).\n"
          parts[:tran_name] << "/* transcript_name(tran_#{ tran.id }, '#{ tran.name.downcase }'). */\n" if tran.name

          # Protein info.
          tran.proteins.each do |prot|
            build_prolog_proteins(gene.species, tran, prot, parts, prots)
          end
          build_prolog_proteins(gene.species, tran, tran.own_protein, parts, prots, true) if tran.own_protein
        end
      end
    end
    build_prolog_file(parts)
  end

  def dataset
    dataset = [['Proteins', 'Occurrences']]
    binds.each { |bind| dataset << [bind.name, bind.count] }
    dataset
  end

  private

  def destroy_files
    if self.files
      grid_fs = Mongoid::GridFs
      self.files.each do |key, file_id|
        grid_fs.delete(file_id)
      end
    end
  end

  def query_required
    return !self.complete
  end

  def build_prolog_proteins(species, tran, prot, parts, prots, own = false)
    id = "#{ species }-#{ prot.name }"
    unless prots[id]
      prots[id] = "prot_#{ prot.id }"
      parts[:prot_id] << "protein(prot_#{ prot.id }).\n"
      parts[:prot_name] << "/* protein_name(prot_#{ prot.id }, '#{ prot.name.downcase }'). */\n"
      parts[:prot_species] << "protein_species(prot_#{ prot.id }, '#{ prot.species.downcase }').\n" if prot.species
      prot.tissues.each { |tissue| parts[:prot_tissue] << "protein_tissue(prot_#{ prot.id }, '#{ tissue.downcase.gsub("'", '') }').\n" }
      prot.keywords.each { |keyword| parts[:prot_keyword] << "protein_keyword(prot_#{ prot.id }, '#{ keyword.downcase.gsub("'", '') }').\n" }
      prot.biological_process.each { |bio| parts[:prot_bio] << "protein_biological_process(prot_#{ prot.id }, '#{ bio.downcase.gsub("'", '') }').\n" }
      prot.cellular_component.each { |cel| parts[:prot_cel] << "protein_cellular_component(prot_#{ prot.id }, '#{ cel.downcase.gsub("'", '') }').\n" }
      prot.molecular_function.each { |mol| parts[:prot_mol] << "protein_molecular_function(prot_#{ prot.id }, '#{ mol.downcase.gsub("'", '') }').\n" }
      prot.pathways.each { |path_id, name| parts[:prot_pathway] << "protein_pathway(prot_#{ prot.id }, path_#{ path_id[/[0-9]+$/] }).\n" }
      prot.positions.map { |pos| pos.sequence }.uniq.each { |seq| parts[:prot_sequence] << "protein_sequence(prot_#{ prot.id }, \"#{ seq }\").\n" }
    end
    if own
      parts[:tran_own] << "transcript_own_protein(tran_#{ tran.id }, #{ prots[id] }).\n"
    else
      parts[:tran_prot] << "transcript_protein(tran_#{ tran.id }, #{ prots[id] }).\n"
    end
  end

  def init_prolog_hash
    {
      info: init_info_comment,
      gene_id: "/* Genes */\n",
      gene_name: "/* Gene names */\n",
      gene_species: "/* Gene species */\n",
      gene_tran: "/* Gene transcripts */\n",
      tran_id: "/* Transcripts */\n",
      tran_name: "/* Transcript names */\n",
      tran_own: "/* Transcript own proteins */\n",
      tran_prot: "/* Transcript proteins */\n",
      prot_id: "/* Proteins */\n",
      prot_name: "/* Protein names */\n",
      prot_tissue: "/* Protein tissues */\n",
      prot_keyword: "/* Protein keywords */\n",
      prot_bio: "/* Protein biological processes */\n",
      prot_cel: "/* Protein cellular components */\n",
      prot_mol: "/* Protein molecular functions */\n",
      prot_species: "/* Protein species */\n",
      prot_sequence: "/* Protein binding sequences */\n",
      prot_pathway: "/* Protein pathways */\n"
    }
  end

  def init_info_comment
    info = "/* Available knowledge base clauses */\n\n"
    info << "/* gene(GENE_ID). */\n"
    info << "/* transcript(TRANSCRIPT_ID). */\n"
    info << "/* protein(PROTEIN_ID). */\n"
    info << "/* gene_name(GENE_ID, 'NAME'). */\n"
    info << "/* gene_species(GENE_ID, 'SPECIES'). */\n"
    info << "/* gene_transcript(GENE_ID, TRANSCRIPT_ID). */\n"
    info << "/* transcript_name(TRANSCRIPT_ID, 'NAME'). */\n"
    info << "/* transcript_own_protein(TRANSCRIPT_ID, PROTEIN_ID). */\n"
    info << "/* transcript_protein(TRANSCRIPT_ID, PROTEIN_ID). */\n"
    info << "/* protein_name(PROTEIN_ID, 'NAME'). */\n"
    info << "/* protein_tissue(PROTEIN_ID, 'TISSUE'). */\n"
    info << "/* protein_keyword(PROTEIN_ID, 'KEYWORD'). */\n"
    info << "/* protein_biological_process(PROTEIN_ID, 'BIOLOGICAL_PROCESS'). */\n"
    info << "/* protein_molecular_function(PROTEIN_ID, 'MOLECULAR_FUNCTION'). */\n"
    info << "/* protein_cellular_component(PROTEIN_ID, 'CELLULAR_COMPONENT'). */\n"
    info << "/* protein_species(PROTEIN_ID, 'SPECIES'). */\n"
    info << "/* protein_sequence(PROTEIN_ID, \"SEQUENCE\"). */\n"
    info << "/* protein_pathway(PROTEIN_ID, PATHWAY_ID). */\n"
    info
  end

  def build_prolog_file(parts)
    file = parts[:info] << "\n"
    file << parts[:gene_id] << "\n"
    file << parts[:tran_id] << "\n"
    file << parts[:prot_id] << "\n"
    file << parts[:gene_name] << "\n"
    file << parts[:gene_species] << "\n"
    file << parts[:gene_tran] << "\n"
    file << parts[:tran_name] << "\n"
    file << parts[:tran_own] << "\n"
    file << parts[:tran_prot] << "\n"
    file << parts[:prot_name] << "\n"
    file << parts[:prot_species] << "\n"
    file << parts[:prot_keyword] << "\n"
    file << parts[:prot_tissue] << "\n"
    file << parts[:prot_bio] << "\n"
    file << parts[:prot_cel] << "\n"
    file << parts[:prot_mol] << "\n"
    file << parts[:prot_sequence] << "\n"
    file << parts[:prot_pathway] << "\n"
  end
end
