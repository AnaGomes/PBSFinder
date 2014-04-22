module Pbs
  class External

    def initialize(helper = nil)
      @helper = helper
    end

    # Finds additional IDs to complement formation about a given gene list.
    #
    # Input:
    #   - genes: array GeneContainer objects
    #   - uniprot: array of used Uniprot IDs
    # Output:
    #   - none
    def find_additional_info(genes, uniprot)
      return unless genes.size > 0 && uniprot.size > 0

      # Convert Uniprot IDs.
      converted = @helper.convert_ids(uniprot, @helper.config[:formats][:unprt], [ @helper.config[:formats][:engid], @helper.config[:formats][:ezgid] ])
      genes.each do |gene|
        (gene.transcripts || []).each do |trans, v1|
          next unless v1
          (v1[:proteins] || []).each do |protein, values|
            if values && values[:uniprot_id]
              values[:ensembl_id] = converted[values[:uniprot_id]].find { |x| x =~ /^(ENS|FB)[A-Z]*[0-9]+$/ }
              values[:ncbi_id] = converted[values[:uniprot_id]].find { |x| x =~ /^[0-9]+$/ }
            end
          end
        end
      end
    end

  end
end
