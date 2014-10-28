module Gofer
  class Debug
    attr_reader :opts, :original_cmd, :object, :env, :response, :cmd
    extend Forwardable

    def_delegator "response.exit_status", :>=
    def_delegator "response.exit_status", :>
    def_delegator "response.exit_status", :<
    def_delegator "response.exit_status", :<=
    def_delegator "response.exit_status", :==
    def_delegator :response, :to_s
    def_delegator :response, :stdout
    def_delegator :response, :stderr
    def_delegator :response, :output
    def_delegator :response, :exit_status

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
        raise ArgumentError, "@response already set."
      end
    end

    def cmd=(value)
      if ! @cmd
        @cmd = value
      else
        raise ArgumentError, "@cmd already set."
      end
    end

    def raise_if_asked
      if ! opts[:capture_exit_status] && response.exit_status != 0
        raise Error.new(object, response, cmd)
      end

      self
    end
  end
end
