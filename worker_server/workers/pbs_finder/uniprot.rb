require_relative 'gene_container'
require 'set'
require 'csv'

module Pbs
  class Uniprot

    def initialize(helper = nil)
      @helper = helper
    end

    # Finds Uniprot IDs to complement information about a given gene list.
    #
    # Input:
    #   - genes: array GeneContainer objects
    # Output:
    #   - none
    def find_additional_info(genes, proteins)
      return unless genes.size > 0 && proteins.size > 0

      # Build query.
      taxons = find_taxons(genes)
      query = '(' + (taxons.map { |taxon| "organism:#{taxon}"} << 'organism:9606').join('+OR+') + ')'
      query += '+AND+(' + proteins.map { |protein, v| "gene:#{protein}"}.join('+OR+') + ')'
      params = @helper.config[:uniprot][:parameters].merge({ @helper.config[:uniprot][:parameter_query] => query })
      uri = URI::HTTP.build(
        :host => @helper.config[:uniprot][:url],
        :path => @helper.config[:uniprot][:entry_path],
        :query => params.map{ |k,v| "#{k}=#{v}" }.join('&')
      )
      begin
        response = Net::HTTP.get_response(uri)
        while response.code == "301" || response.code == "302"
          response = Net::HTTP.get_response(URI.parse(response.header['location']))
        end
        return unless response.body && !response.body.empty?
        parse_uniprot_response(genes, proteins, response.body)
      rescue Exception => e
        puts e.message, e.backtrace
        retry
      end
    end

    private
    def parse_uniprot_response(genes, proteins, response)
      # Parse response.
      uniprots = {}
      CSV.parse(response, headers: true, col_sep: "\t") do |row|
        uniprots[row['Organism ID']] ||= { rev: [], no_rev: [] }
        uniprots[row['Organism ID']][row['Status'] == 'reviewed' ? :rev : :no_rev] << { name: row['Gene names'].upcase.split(' ') , id: row['Entry'] }
      end

      # Build general protein list (using human analogues).
      hsapiens = uniprots['9606']
      if hsapiens
        proteins.each do |protein, values|
          values[:id] = find_uniprot_id(hsapiens, protein)
        end
      end

      # Build proteins by transcript.
      genes.each do |gene|
        (gene.transcripts || []).each do |trans, v1|
          next unless v1
          (v1[:proteins] || []).each do |protein, v2|
            if protein
              v2[:uniprot_id] = find_uniprot_id(uniprots[gene.taxon], protein) || find_uniprot_id(uniprots['9606'], protein)
            end
          end
        end
      end
    end

    def find_uniprot_id(results, protein)
      return nil unless results
      res = nil
      protein = protein.gsub('-', '')
      if results[:rev]
        uni = results[:rev].find { |x| x[:name].include?(protein) }
        res = uni[:id] if uni
      end
      if !res && results[:no_rev]
        uni = results[:no_rev].find { |x| x[:name].include?(protein) }
        res = uni[:id] if uni
      end
      return res
    end

    def find_taxons(genes)
      taxons = Set.new
      taxons.add(@helper.config[:species]['ENS'])
      genes.each do |gene|
        taxons.add(gene.taxon) if gene.taxon
      end
      return taxons.to_a
    end

  end
end
