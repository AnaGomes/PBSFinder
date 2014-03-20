class Transcript

  include Mongoid::Document
  embedded_in :gene
  embeds_many :proteins, :cascade_callbacks => true

  field :name,          :type => String
  field :converted_id,  :type => String
  field :utr5,          :type => String
  field :utr3,          :type => String
  field :downstream,    :type => String
  field :matches,       :type => Array

  def dataset_json
    dataset = [['Protein', 'Locations']]
    proteins.each do |prot|
      dataset << [prot.name, prot.positions.size]
    end
    dataset.to_json
  end

end
