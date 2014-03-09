class Transcript
  include Mongoid::Document
  embedded_in :gene
  embeds_many :proteins, :cascade_callbacks => true

  # field <name>, :type => <type>, :default => <value>
  field :name, :type => String
  field :ensembl_id, :type => String
  field :utr5, :type => String
  field :utr3, :type => String

  # You can define indexes on documents using the index macro:
  # index :field <, :unique => true>

  # You can create a composite key in mongoid to replace the default id using the key macro:
  # key :field <, :another_field, :one_more ....>
end
