module Pbs
  module Analyzer
    # Establishes relationships between the obtained data and the UniProt
    # service.
    class Uniprot
      def initialize(helper = nil)
        @helper = helper
      end

      def find_uniprot_info!(job)
        # Request UniProt pages.
        response = nil
        begin
          uri = URI::HTTP.build(
            host: @helper.config[:uniprot][:url],
            path: @helper.config[:uniprot][:batch_path]
          )
          response = Net::HTTP.post_form(
            uri,
            @helper.config[:uniprot][:parameters_batch].merge({
              @helper.config[:uniprot][:parameter_query] => job.protein_ids.to_a.join(' ')
            })
          )
          while response.code == '301' || response.code == '302'
            response = Net::HTTP.get_response(URI.parse(response.header['location']))
          end
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end

        # Parse the response.
        if response && response.body && !response.body.empty?
          parse_uniprot_flatfiles!(job, response.body)
        end
      end

      def find_uniprot_ids!(job)
        # Create the queries.
        build_protein_list!(job)
        queries = build_uniprot_queries(job, 50)
        uniprots = {}

        # Parse the UniProt responses.
        begin
          queries.each do |query|
            uri = build_uniprot_uri(query)
            response = Net::HTTP.get_response(uri)
            while response.code == "301" || response.code == "302"
              response = Net::HTTP.get_response(URI.parse(response.header['location']))
            end
            if response && response.body && !response.body.empty?
              parse_uniprot_query!(response.body, uniprots)
            end
          end
        rescue StandardError => e
          puts e.message, e.backtrace
          retry
        end

        # Parse UniProt request.
        begin
          parse_uniprot_response!(job, uniprots)
        rescue StandardError => e
          puts e.message, e.backtrace
        end

        # Remove any unusable proteins and build a UniProt ID list.
        build_id_list!(job)
      end

      private

      def parse_uniprot_flatfiles!(job, response)
        # TODO PARSE RESPONSE.
      end

      def build_id_list!(job)
        job.proteins.select! { |prot| prot.protein_id }
        job.proteins.each do |prot|
          job.protein_ids.add(prot.protein_id)
        end
      end

      def build_uniprot_query(job)
        query = '(' + (job.taxons.map { |taxon| "organism:#{ taxon }" } << 'organism:9606').join('+OR+') + ')'
        query += '+AND+(' + job.proteins.map { |protein| "gene:#{ protein.name }" }.join('+OR+') + ')'
        query
      end

      def build_uniprot_uri(query)
        # Create the base query.
        params = @helper.config[:uniprot][:parameters].merge(
          { @helper.config[:uniprot][:parameter_query] => query }
        )
        uri = URI::HTTP.build(
          host: @helper.config[:uniprot][:url],
          path: @helper.config[:uniprot][:entry_path],
          query: params.map{ |k,v| "#{ k }=#{ v }" }.join('&')
        )
        uri
      end

      def build_uniprot_queries(job, limit = nil)
        queries = []
        unless limit
          queries << build_uniprot_query(job)
        else
          queries = []
          species = '(' + (job.taxons.map { |taxon| "organism:#{ taxon }" } << 'organism:9606').join('+OR+') + ')'
          job.proteins.each_slice(limit) do |slice|
            queries << species + '+AND+(' + slice.map { |protein| "gene:#{ protein.name }" }.join('+OR+') + ')'
          end
        end
        queries
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

      def parse_uniprot_query!(response, uniprots = {})
        CSV.parse(response, headers: true, col_sep: "\t") do |row|
          uniprots[row['Organism ID']] ||= { rev: [], no_rev: [] }
          uniprots[row['Organism ID']][row['Status'] == 'reviewed' ? :rev : :no_rev] << {
            name: row['Gene names'].upcase.split(' ') ,
            id: row['Entry']
          }
        end
      end

      def parse_uniprot_response!(job, uniprots)
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
