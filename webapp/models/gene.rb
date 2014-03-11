class Gene

  include Mongoid::Document
  embedded_in :job
  embeds_many :transcripts, :cascade_callbacks => true

  field :name,          :type => String
  field :ensembl_id,    :type => String
  field :binds,         :type => Boolean, :default => false

end
