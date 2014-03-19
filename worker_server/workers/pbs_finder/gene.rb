module Pbs
  class Gene

    attr_accessor :id, :original_id, :transcripts, :name, :species, :type
    def initialize(original_id = nil)
      @original_id = original_id
    end

  end
end
