module Gofer
  class ClusterError < Exception
    attr_reader :errors

    def initialize(errors = {})
      @errors = errors
      super(errors.values.map(&:to_s).join(', '))
    end
  end
end
