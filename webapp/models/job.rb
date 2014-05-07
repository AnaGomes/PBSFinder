require 'csv'
require 'set'

class Job
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to  :account
  embeds_many :binds,   cascade_callbacks: true
  has_many    :genes,   dependent: :delete, autosave: true

  attr_accessor :query

  field :complete,      type: Boolean, default: false
  field :description,   type: String
  field :notify,        type: Boolean, default: false
  field :time,          type: Integer

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
      header += %w[tissues molecular_function cellular_component biological_process]
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
              prot.biological_process.map(&:downcase).join(';')
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
              prot.biological_process.map(&:downcase).join(';')
            ]
            csv << line + line2
          end
        end
      end
    end
  end

  def dataset
    dataset = [['Proteins', 'Occurrences']]
    binds.each { |bind| dataset << [bind.name, bind.count] }
    dataset
  end

  private
  def query_required
    return !self.complete
  end
end
