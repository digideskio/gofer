module Gofer
  class Debug
    attr_reader :response, :original_cmd, :cmd, :opts, :env

    def initialize(original_cmd, opts, env, object)
      @opts = opts
      @original_cmd = original_cmd
      @object = object
      @env = env
    end

    def inspect
      %Q{<#{self.class} #{@original_cmd}>}
    end

    def response=(value)
      if ! @response
        @response = value
      else
        raise ArgumentError, "Value already set."
      end
    end

    def cmd=(value)
      if ! @cmd
        @cmd = value
      else
        raise ArgumentError, "Value already set."
      end
    end

    # I return self here so that it can be called last in a long line of calls
    # and simply just return self so you don't need to also add `return debug` to
    # whatever you are doing.

    def raise_if_asked
      if ! @opts[:capture_exit_status] && @response.exit_status != 0
        raise Error.new(@object, @response, @cmd)
      end

      self
    end
  end
end
