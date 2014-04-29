module Pbs
  module Container
    # Simple container for protein information.
    class Protein
      attr_accessor(
        :taxon,
        :name,
        :positions,
        :protein_id,
        :external_ids,
        :tissues
      )

      def initialize(params = {})
        @name = params.fetch(:name, nil)
        @positions = params.fetch(:positions, [])
        @protein_id = params.fetch(:protein_id, nil)
        @external_ids = params.fetch(:external_ids, {})
        @tissues = params.fetch(:tissues, [])
        @taxon = params.fetch(:taxon, nil)
      end
    end
  end
end
