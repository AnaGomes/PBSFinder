class Position
  include Mongoid::Document
  embedded_in :protein

  # field <name>, :type => <type>, :default => <value>
  field :seq_start, :type => Integer
  field :seq_end, :type => Integer
  field :score, :type => Integer
  field :sequence, :type => String

  # You can define indexes on documents using the index macro:
  # index :field <, :unique => true>

  # You can create a composite key in mongoid to replace the default id using the key macro:
  # key :field <, :another_field, :one_more ....>
end
