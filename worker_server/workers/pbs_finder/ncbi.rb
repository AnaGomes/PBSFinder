require_relative 'gene'

module Pbs
  class Ncbi

    ############################################################################
    # PUBLIC METHODS
    ############################################################################

    def initialize(helper = nil)
      @helper = helper
    end

    # Processes a list of IDs and tries to identify/convert them.
    #
    # Input:
    #   - ids: array of strings (IDs)
    # Output:
    #   - array of Gene objects
    def process_ids(ids)
      # TODO
      return []
    end

    # Finds protein binding sites for a list of genes.
    #
    # Input:
    #   - array of Gene objects
    # Output:
    #   - array of Gene objects
    def find_protein_binding_sites(genes)
      # TODO
      return []
    end

  end
end
