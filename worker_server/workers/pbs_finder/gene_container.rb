module Pbs
  class GeneContainer

    attr_accessor :id, :original_id, :transcripts, :name, :species, :type, :taxon
    def initialize(original_id = nil)
      @original_id = original_id
    end

  end
end
