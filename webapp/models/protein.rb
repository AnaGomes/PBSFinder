class Protein
  include Mongoid::Document
  belongs_to      :transcript, class_name: 'Transcript', inverse_of: :proteins
  belongs_to      :own_transcript, class_name: 'Transcript', inverse_of: :own_protein
  embeds_many     :positions, :cascade_callbacks => true

  field :protein_id,        type: String
  field :name,              type: String
  field :external_ids,      type: Hash
  field :tissues,           type: Array
end
