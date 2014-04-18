class Transcript

  include Mongoid::Document

  belongs_to              :gene
  has_and_belongs_to_many :proteins, :dependent => :delete
  has_one                 :protein, :dependent => :delete

  field :transcript_id,   :type => String
  field :name,            :type => String
  field :utr5,            :type => String
  field :utr3,            :type => String
  field :downstream,      :type => String
  field :id_type,         :type => Symbol
  field :matches,         :type => Array

  def dataset_json
    dataset = [['Protein', 'Locations']]
    proteins.each do |prot|
      dataset << [prot.name, prot.positions.size]
    end
    dataset.to_json
  end

end
