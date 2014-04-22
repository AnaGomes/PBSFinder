module Pbs
  module Container
    # Simple container for gene information.
    class Gene
      attr_accessor(
        :gene_id, :original_id, :transcripts, :name, :species, :type, :taxon, :binds
      )

      def initialize(params = {})
        @gene_id = params.fetch(:gene_id, nil)
        @original_id = params.fetch(:original_id, nil)
        @transcripts = params.fetch(:transcripts, {})
        @name = params.fetch(:name, nil)
        @species = params.fetch(:species, nil)
        @type = params.fetch(:type, nil)
        @taxon = params.fetch(:taxon, nil)
        @binds = params.fetch(:binds, false)
      end
    end
  end
end
