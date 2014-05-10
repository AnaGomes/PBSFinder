module Pbs
  module Container
    # Simple container for protein information.
    class Protein
      attr_accessor(
        :species,
        :taxon,
        :name,
        :positions,
        :protein_id,
        :external_ids,
        :tissues,
        :keywords,
        :biological_process,
        :cellular_component,
        :molecular_function,
        :pathways
      )

      def initialize(params = {})
        @name = params.fetch(:name, nil)
        @positions = params.fetch(:positions, [])
        @protein_id = params.fetch(:protein_id, nil)
        @external_ids = params.fetch(:external_ids, {})
        @tissues = params.fetch(:tissues, [])
        @taxon = params.fetch(:taxon, nil)
        @species = params.fetch(:species, nil)
        @keywords = params.fetch(:keywords, [])
        @biological_process = params.fetch(:biological_process, [])
        @cellular_component = params.fetch(:cellular_component, [])
        @molecular_function = params.fetch(:molecular_function, [])
        @pathways = params.fetch(:pathways, {})
      end
    end
  end
end
