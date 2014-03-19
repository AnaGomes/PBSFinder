module Biomart
  class Dataset
    include Biomart
    def dataset_xml( xml, dataset, args )
      xml.Dataset( :name => dataset.name, :interface => "default" ) {

        if args[:filters]
          args[:filters].each do |name,value|

            # BEGIN MODIFICATION
            if name == 'downstream_flank' && !dataset.attributes[name].nil?
              dataset.filters[name] = Filter.new({'type' => 'string', 'name' => name})
            end
            # END MODIFICATION

            raise Biomart::ArgumentError, "The filter '#{name}' does not exist" if dataset.filters[name].nil?

            if dataset.filters[name].type == 'boolean'
              value = value.downcase if value.is_a? String
              if [true,'included','only'].include?(value)
                xml.Filter( :name => name, :excluded => '0' )
              elsif [false,'excluded'].include?(value)
                xml.Filter( :name => name, :excluded => '1' )
              else
                raise Biomart::ArgumentError, "The boolean filter '#{name}' can only accept 'true/included/only' or 'false/excluded' arguments."
              end
            else
              value = value.join(",") if value.is_a? Array
              xml.Filter( :name => name, :value => value )
            end
          end
        else
          dataset.filters.each do |name,filter|
            if filter.default?
              if filter.type == 'boolean'
                xml.Filter( :name => name, :excluded => filter.default_value )
              else
                xml.Filter( :name => name, :value => filter.default_value )
              end
            end
          end
        end

        unless args[:count]
          if args[:attributes]
            args[:attributes].each do |name|
              xml.Attribute( :name => name )
            end
          else
            dataset.attributes.each do |name,attribute|
              if attribute.default?
                xml.Attribute( :name => name )
              end
            end
          end
        end
      }
    end
  end
end


