module Gofer
  class Base
    attr_reader :hostname, :username

    KNOWN_OPTS = [
      :stderr, :stdout, :stdio, :ansi,
      :output_prefix, :capture_exit_status, :quiet_stdout,
      :quiet_stderr, :timeout
    ]

    def initialize(opts = {})
      @capture_exit_status = opts[:capture_exit_status]
      @stdio_class, @stdio_opts = opts[:stdio] || Stdio, {}
      @timeout = opts[:timeout] || 12

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

    def write_stdio(out_err = {})
      # _in is the output returned, _out is the STDOUT (FD).
      out_err[:output] << out_err[:stderr_in] if out_err[:stderr_in]
      out_err[:output] << out_err[:stdout_in] if out_err[:stdout_in]
      stdio.stderr(out_err[:stderr_in], out_err[:opts]) if out_err[:stderr_in]
      stdio.stdout(out_err[:stdout_in], out_err[:opts]) if out_err[:stdout_in]
      out_err[:stderr_out] << out_err[:stderr_in] if out_err[:stderr_in] && out_err[:stderr_out]
      out_err[:stdout_out] << out_err[:stdout_in] if out_err[:stdout_in] && out_err[:stdout_out]
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
