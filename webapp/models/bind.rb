class Bind

  include Mongoid::Document

  field :count,         :type => Integer, :default => 0
  field :name,          :type => String
  field :protein_id,    :type => String

  embedded_in :job

end
