module Pbs
  module Container
    # Simple container for job information.
    class Job
      attr_accessor :time, :genes, :binds, :species, :taxons

      def initialize(params = {})
        @time = params.fetch(:time, nil)
        @genes = params.fetch(:genes, [])
        @binds = params.fetch(:binds, {})
        @species = params.fetch(:species, Set.new)
        @taxons = params.fetch(:taxons, Set.new)
      end
    end
  end
end
