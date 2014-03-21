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
      clean_ids(ids)
      genes = convert_ids(ids.select { |id| id =~ /^[A-Z]+[0-9]+$/ }, @helper.config[:formats][:genna], [ @helper.config[:formats][:engid], @helper.config[:formats][:ezgid] ])
      genes += convert_ids(ids.select { |id| id =~ /^[A-Z]+_[0-9]+$/ }, @helper.config[:formats][:rseqr], [ @helper.config[:formats][:engid], @helper.config[:formats][:ezgid] ])
      genes += convert_from_geneid(ids.select { |id| id =~ /^[0-9]+$/ })
      return genes
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

    ############################################################################
    # PRIVATE METHODS
    ############################################################################
    private

    def clean_ids(ids)
      ids.each_with_index do |id, i|
        ids[i] = id.split(".")[0]
      end
    end

    def convert_ids(ids, input, output)
      genes = []
      ensembl = []
      converted_ids = @helper.convert_ids(ids, input, output)
      converted_ids.each do |id, values|
        gene = Gene.new(id)
        converted = values.find { |x| x }
        if converted
          if converted =~ /^[0-9]+$/
            gene.id = converted
            gene.type = :ncbi
            genes << gene
          else
            gene.id = converted
            ensembl << gene
          end
        end
      end
      @helper.determine_ensembl_species(ensembl)
      return genes + ensembl
    end

    def convert_from_geneid(ids)
      genes = []
      ensembl = []
      converted_ids = @helper.convert_ids(ids, @helper.config[:formats][:ezgid], [ @helper.config[:formats][:engid] ])
      converted_ids.each do |id, values|
        gene = Gene.new(id)
        converted = values.find { |x| x }
        if converted
          gene.id = converted
          ensembl << gene
        else
          gene.id = id
          gene.type = :ncbi
          genes << gene
        end
      end
      @helper.determine_ensembl_species(ensembl)
      return genes + ensembl
    end

  end
end
