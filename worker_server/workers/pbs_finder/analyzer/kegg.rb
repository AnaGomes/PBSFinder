module Pbs
  module Analyzer
    # Finds KEGG pathways and other relevant information.
    class Kegg
      def initialize(helper = nil)
        @helper = helper
      end

      def find_kegg_pathways!(job)
        proteins = index_by_kegg_id(job)
        if proteins.size > 0
          get_kegg_pages!(proteins)
        end
      end

      private

      def index_by_kegg_id(job)
        proteins = {}
        job.proteins.each do |prot|
          prot.external_ids.each do |type, values|
            if type == :kegg
              values.each do |val|
                proteins[val[0]] ||= []
                proteins[val[0]] << prot
              end
            end
          end
        end
        proteins
      end

      def get_kegg_pages!(proteins)
        ids = proteins.keys
        ids.each_slice(10) do |slice|
          uri = URI::HTTP.build(
            host: @helper.config[:kegg][:url],
            path: @helper.config[:kegg][:get_path] + slice.join('+'),
          )
          begin
            flat = Bio::FlatFile.open_uri(uri)
            parse_kegg_pages!(proteins, flat) if flat
          rescue StandardError => e
            puts e.message, e.backtrace
            retry
          end
        end
      end

      def parse_kegg_pages!(proteins, flat)
        flat.each do |kegg|
          begin
            id = "#{ kegg.fetch('ORGANISM').split(' ')[0] }:#{ kegg.entry_id }"
            proteins[id].each do |prot|
              prot.pathways.merge!(kegg.pathways)
            end
          rescue StandardError => e
            puts e.message, e.backtrace
          end
        end
      end
    end
  end
end
