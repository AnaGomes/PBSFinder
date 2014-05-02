class Protein
  include Mongoid::Document
  belongs_to      :transcript, class_name: 'Transcript', inverse_of: :proteins
  belongs_to      :own_transcript, class_name: 'Transcript', inverse_of: :own_protein
  embeds_many     :positions, :cascade_callbacks => true

  field :protein_id,          type: String
  field :name,                type: String
  field :external_ids,        type: Hash
  field :tissues,             type: Array
  field :keywords,            type: Array
  field :biological_process,  type: Array
  field :cellular_component,  type: Array
  field :molecular_function,  type: Array
  field :species,             type: String
end
