class Gene
  include Mongoid::Document
  belongs_to  :job
  has_many    :transcripts, dependent: :delete, autosave: true

  field :query_id,      type: String
  field :gene_id,       type: String
  field :name,          type: String
  field :species,       type: String
  field :taxon,         type: String
  field :id_type,       type: Symbol
  field :binds,         type: Boolean, default: false
end
