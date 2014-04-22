module Pbs
  module Container
    # Simple container for protein position information.
    class Position
      attr_accessor :seq, :start, :end, :score

      def initialize(params = {})
        @seq = params.fetch(:seq, nil)
        @start = params.fetch(:start, nil)
        @end = params.fetch(:end, nil)
        @score = params.fetch(:score, nil)
      end
    end
  end
end
