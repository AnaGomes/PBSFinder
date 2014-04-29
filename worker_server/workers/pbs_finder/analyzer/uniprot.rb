module Pbs
  module Analyzer
    # Establishes relationships between the obtained data and the UniProt
    # service.
    class Uniprot
      def initialize(helper = nil)
        @helper = helper
      end

      def find_uniprot_ids!(job)
        # Create the base query.
        build_protein_list!(job)
        query = build_uniprot_query(job)
        params = @helper.config[:uniprot][:parameters].merge(
          { @helper.config[:uniprot][:parameter_query] => query }
        )
        uri = URI::HTTP.build(
          host: @helper.config[:uniprot][:url],
          path: @helper.config[:uniprot][:entry_path],
          query: params.map{ |k,v| "#{ k }=#{ v }" }.join('&')
        )

        # Make UniProt request and parse the response.
        begin
          response = Net::HTTP.get_response(uri)
          while response.code == "301" || response.code == "302"
            response = Net::HTTP.get_response(URI.parse(response.header['location']))
          end
          if response.body && !response.body.empty?
            parse_uniprot_response!(job, response.body)
          end
        rescue StandardError => e
          puts e.message, e.backtrace
        end

        # Remove any unusable proteins and build a UniProt ID list.
        build_id_list!(job)
      end

      private

      def build_id_list!(job)
        job.proteins.select! { |prot| prot.protein_id }
        job.proteins.each do |prot|
          job.protein_ids.add(prot.name)
        end
      end

      def build_uniprot_query(job)
        query = '(' + (job.taxons.map { |taxon| "organism:#{ taxon }" } << 'organism:9606').join('+OR+') + ')'
        query += '+AND+(' + job.proteins.map { |protein| "gene:#{ protein.name }" }.join('+OR+') + ')'
        query
      end

      def build_protein_list!(job)
        job.genes.each do |gene|
          gene.transcripts.each do |trans_id, trans|
            p = trans.own_protein
            if p
              p.taxon = gene.taxon
              job.proteins << p
            end
            trans.proteins.each do |prot_name, prot|
              prot.taxon = gene.taxon
              job.proteins << prot
            end
          end
        end
      end

      def parse_uniprot_response!(job, response)
        # Parse response and retrieve UniProt IDs.
        uniprots = {}
        CSV.parse(response, headers: true, col_sep: "\t") do |row|
          uniprots[row['Organism ID']] ||= { rev: [], no_rev: [] }
          uniprots[row['Organism ID']][row['Status'] == 'reviewed' ? :rev : :no_rev] << {
            name: row['Gene names'].upcase.split(' ') ,
            id: row['Entry']
          }
        end

        # Build bind list (using human analogues).
        hsapiens = uniprots['9606']
        if hsapiens
          job.binds.each do |protein_name, bind|
            bind.protein_id = find_uniprot_id(hsapiens, protein_name)
          end
        end

        # Build the rest of the proteins.
        job.proteins.each do |protein|
          protein.protein_id = find_uniprot_id(uniprots[protein.taxon], protein.name)
          protein.protein_id ||= find_uniprot_id(uniprots['9606'], protein.name)
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
    end
  end
end
