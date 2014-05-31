module Pbs
  module Container
    # Simple container for protein information.
    class ClusterProtein
      attr_accessor(
        :protein,
        :genes,
        :keywords,
        :tissues,
        :pathways,
        :biological_process,
        :molecular_function,
        :cellular_component
      )

      def initialize(params = {})
        @protein = params.fetch(:protein, nil)
        @genes = params.fetch(:genes, [])
        @tissues = params.fetch(:tissues, [])
        @keywords = params.fetch(:keywords, [])
        @pathways = params.fetch(:pathways, [])
        @biological_process = params.fetch(:biological_process, [])
        @cellular_component = params.fetch(:cellular_component, [])
        @molecular_function = params.fetch(:molecular_function, [])
      end
    end
  end
end
