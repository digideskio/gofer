module Gofer
  class Debug
    attr_reader :opts, :original_cmd, :env, :cmd
    extend Forwardable

    def_delegator "@response.exit_status", :>=
    def_delegator "@response.exit_status", :>
    def_delegator "@response.exit_status", :<
    def_delegator "@response.exit_status", :<=
    def_delegator "@response.exit_status", :==
    def_delegator :@response, :each_line
    def_delegator :@response, :to_enum
    def_delegator :@response, :lines
    def_delegator :@response, :strip
    def_delegator :@response, :to_s
    def_delegator :@response, :stdout
    def_delegator :@response, :stderr
    def_delegator :@response, :combined
    def_delegator :@response, :exit_status
    def_delegator :@object, :to_s, :host

    def initialize(original_cmd, opts, env, object)
      @opts = opts
      @object = object
      @original_cmd = original_cmd
      @env = env
    end

    def inspect
      %Q{<#{self.class} #{@original_cmd}>}
    end

    def response=(value)
      raise ArgumentError, "@response alredy set" if @response
      raise ArgumentError, "value must be an array" unless value.is_a?(Array)
      @response = Gofer::Response.new(*value)
    end

    def cmd=(value)
      if ! @cmd
        @cmd = value
      else
        raise ArgumentError, "@cmd already set."
      end
    end

    def raise_if_asked
      if ! opts[:capture_exit_status] && self != 0
        raise Error.new(host, @response, cmd)
      end

      self
    end
  end
end
