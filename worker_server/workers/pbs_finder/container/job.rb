module Pbs
  module Container
    # Simple container for job information.
    class Job
      attr_accessor(
        :time,
        :genes,
        :binds,
        :species,
        :taxons,
        :proteins,
        :protein_ids,
        :cluster_proteins,
        :attr_converter,
        :cluster_info,
        :cluster_genes
      )

      def initialize(params = {})
        @time = params.fetch(:time, nil)
        @genes = params.fetch(:genes, [])
        @binds = params.fetch(:binds, {})
        @species = params.fetch(:species, Set.new)
        @taxons = params.fetch(:taxons, Set.new)
        @protein_ids = params.fetch(:protein_ids, Set.new)
        @proteins = params.fetch(:proteins, [])
        @cluster_proteins = params.fetch(:cluster_proteins, {})
        @cluster_genes = params.fetch(:cluster_genes, {})
        @cluster_info = params.fetch(:cluster_info, [])
        @attr_converter = params.fetch(:attr_converter, {})
      end
    end
  end
end
