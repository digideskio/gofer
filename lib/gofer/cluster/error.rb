module Gofer
  class Cluster
    class Error < StandardError
      attr_reader :errors

      def initialize(errors = {})
        @errors = errors
        super(errors.values.map(&:to_s).join(", "))
      end
    end
  end
end
