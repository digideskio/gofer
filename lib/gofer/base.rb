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

    def write_stderr(out)
      write_stdio(
        :stderr, out
      )
    end

    def write_stdout(out)
      write_stdio(
        :stdout, out
      )
    end

    def to_s
      "#{@username}@#{@hostname}"
    end

    def inspect
      %Q{<#{self.class} "#{@username}@#{@hostname}">}
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
    def write_stdio(type, out)
      if out[type] && out[type][:in]
        stdio.send(type, out[type][:in], out[:opts])
        out[type][:out] << out[type][:in] if out[type][:out]
        out[:output] << out[type][:in]
      end
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
