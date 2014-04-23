class Position
  include Mongoid::Document
  embedded_in :protein

  field :seq_start,     type: Integer
  field :seq_end,       type: Integer
  field :score,         type: Integer
  field :sequence,      type: String
end
