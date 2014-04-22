module Pbs
  module Container
    # Simple container for bind information.
    class Bind
      attr_accessor :name, :count, :protein_id

      def initialize(params = {})
        @name = params.fetch(:name, nil)
        @count = params.fetch(:count, 0)
        @protein_id = params.fetch(:protein_id, nil)
      end
    end
  end
end
