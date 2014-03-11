class Protein
  include Mongoid::Document
  embedded_in :transcript
  embeds_many :positions, :cascade_callbacks => true

  field :name,        :type => String

end
