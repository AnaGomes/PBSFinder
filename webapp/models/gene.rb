class Gene
  include Mongoid::Document
  embedded_in :job
  embeds_many :transcripts, :cascade_callbacks => true

  # field <name>, :type => <type>, :default => <value>
  field :name, :type => String
  field :ensembl_id, :type => String

  # You can define indexes on documents using the index macro:
  # index :field <, :unique => true>

  # You can create a composite key in mongoid to replace the default id using the key macro:
  # key :field <, :another_field, :one_more ....>
end
