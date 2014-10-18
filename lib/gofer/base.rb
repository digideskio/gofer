module Gofer
  class Base
    attr_reader :hostname, :username

    KNOWN_OPTS = [
      :stderr, :stdout, :stdio, :ansi,
      :output_prefix, :capture_exit_status, :quiet_stdout,
      :quiet_stderr, :timeout, :env
    ]

    def initialize(opts = {})
      @capture_exit_status = opts[:capture_exit_status]
      @stdio_class, @stdio_opts = opts[:stdio] || Stdio, {}
      @timeout = opts[:timeout] || 12
      @env = opts[:env] || {}

      @stdio_opts[:stdout] = opts[:stdout]
      @stdio_opts[:quiet_stdout] = opts[:quiet_stdout]
      @stdio_opts[:output_prefix] = opts[:output_prefix]
      @stdio_opts[:quiet_stderr] = opts[:quiet_stderr]
      @stdio_opts[:stderr] = opts[:stderr]
      @stdio_opts[:ansi] = opts[:ansi]

      @ssh_opts = opts.delete_if do |k, v|
        KNOWN_OPTS.include?(k)
      end
    end

    # Do a triple for one.  Put it to stdio, put it on the final output and
    # also make sure it makes it on that types individual "output".  That is...
    # output is the string of stderr+stdout, then there is std{err,out} and
    # then there is stdio which redirects where you want it to (IO, StringIO,
    # IO<FD> or other, you decide there.)

    [:stdout, :stderr].each do |k|
      define_method "write_#{k}" do |o = {}|
        if o[k] && o[k][:in]
          stdio.send(k, o[k][:in], o[:opts])
          o[k][:out] << o[k][:in] if o[k][:out]
          o[:output] << o[k][:in]
        end
      end
    end

    def to_s
      "#{@username}@#{@hostname}"
    end

    def inspect
      "<#{self.class} @host = #{@hostname}, @user = #{@username}>"
    end

    private
    def normalize_opts(opts = {})
      opts[:timeout] = @timeout unless opts.has_key?(:timeout)
      opts[:env] = @env.merge(opts[:env] || {}).inject({}) do |h, (k, v)|
        h.update(k.to_s => v.to_s)
      end

      opts[:capture_exit_status] = @capture_exit_status unless \
        opts.has_key?(:capture_exit_status)
    opts
    end

    private
    def raise_if_bad_exit(command, out, opts)
      if ! opts[:capture_exit_status] && out.exit_status != 0
        raise Error.new(self, out, command)
      end
    end

    private
    def stdio
      @stdio ||= @stdio_class.new(@stdio_opts)
    end
  end
end
