class Bind
  include Mongoid::Document
  embedded_in :job

  field :count,         :type => Integer, :default => 0
  field :name,          :type => String
  field :protein_id,    :type => String
end
