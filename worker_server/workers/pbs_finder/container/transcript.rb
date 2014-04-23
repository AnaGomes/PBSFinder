module Pbs
  module Container
    # Simple container for transcript information.
    class Transcript
      attr_accessor(
        :name,
        :transcript_id,
        :proteins,
        :utr5,
        :utr3,
        :downstream,
        :date,
        :matches,
        :own_protein
      )

      def initialize(params = {})
        @name = params.fetch(:name, nil)
        @transcript_id = params.fetch(:transcript_id, nil)
        @proteins = params.fetch(:proteins, {})
        @utr5 = params.fetch(:utr5, nil)
        @utr3 = params.fetch(:utr3, nil)
        @downstream = params.fetch(:downstream, nil)
        @date = params.fetch(:date, nil)
        @matches = params.fetch(:matches, [])
        @own_protein = params.fetch(:own_protein, nil)
      end
    end
  end
end
