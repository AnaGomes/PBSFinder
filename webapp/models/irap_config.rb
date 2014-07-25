class IrapConfig
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to  :account,   index: true

  # Platform specific fields.
  field :description,             type: String

  # Basic fields.
  field :name,                    type: String
  field :species,                 type: String
  field :reference,               type: String
  field :annotation,              type: String
  field :path,                    type: String
  field :cont_path,               type: String

  # Tool fields.
  field :mapper,                  type: String
  field :de_method,               type: String
  field :quant_method,            type: String
  field :gse_tool,                type: String
  field :mapper_override,         type: String
  field :quant_override,          type: String

  # General fields.
  field :qual_filter,             type: Boolean
  field :trim_reads,              type: Boolean
  field :exon_quant,              type: Boolean
  field :transcript_quant,        type: Boolean
  field :max_threads,             type: Integer
  field :min_read_qual,           type: Integer
  field :gse_minsize,             type: Integer
  field :gse_pvalue,              type: Float

  # Required field validation.
  validates_presence_of           :description
  validates_presence_of           :name
  validates_presence_of           :species
  validates_presence_of           :reference
  validates_presence_of           :annotation
  validates_presence_of           :path
  validates_presence_of           :qual_filter
  validates_presence_of           :trim_reads
  validates_presence_of           :exon_quant
  validates_presence_of           :transcript_quant
  validates_presence_of           :max_threads
  validates_presence_of           :min_read_qual
  validates_length_of             :description,   :within => 5..256
  validates_length_of             :name,          :within => 4..256
  validates_length_of             :species,       :within => 4..256
  validates_format_of             :name,          :with => /^[a-z0-9_\-]+$/i
  validates_format_of             :species,       :with => /^[a-z0-9_\-]+$/i
  validates_format_of             :max_threads,   :with => /^[0-9]+$/i
  validates_format_of             :min_read_qual, :with => /^[0-9]+$/i
  validates_format_of             :gse_minsize,   :with => /^[0-9]+$/i
  validates_format_of             :gse_pvalue,    :with => /^(0|1)(\.|,)[0-9]+$/i
end
