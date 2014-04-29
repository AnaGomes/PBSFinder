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
        :protein_ids
      )

      def initialize(params = {})
        @time = params.fetch(:time, nil)
        @genes = params.fetch(:genes, [])
        @binds = params.fetch(:binds, {})
        @species = params.fetch(:species, Set.new)
        @taxons = params.fetch(:taxons, Set.new)
        @protein_ids = params.fetch(:protein_ids, Set.new)
        @proteins = params.fetch(:proteins, [])
      end
    end
  end
end
