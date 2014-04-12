class Gene

  include Mongoid::Document
  embedded_in :job
  embeds_many :transcripts, :cascade_callbacks => true

  field :name,          :type => String
  field :converted_id,  :type => String
  field :original_id,   :type => String
  field :binds,         :type => Boolean, :default => false
  field :species,       :type => String
  field :taxon,         :type => String
  field :org,           :type => Symbol

end
