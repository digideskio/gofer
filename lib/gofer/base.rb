module Gofer
  class Base
    attr_reader :hostname, :username

    KNOWN_OPTIONS = [
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
        KNOWN_OPTIONS.include?(k)
      end
    end

    # A wrapper that de-duplicates stuff to write to Stdio.

    def write_stdio(oe = {})
      oe[:output] << oe[:stderr_in] if oe[:stderr_in]
      oe[:output] << oe[:stdout_in] if oe[:stdout_in]
      stdio.stderr(oe[:stderr_in], oe[:opts]) if oe[:stderr_in]
      stdio.stdout(oe[:stdout_in], oe[:opts]) if oe[:stdout_in]
      oe[:stderr_out] << oe[:stderr_in] if oe[:stderr_in] && oe[:stderr_out]
      oe[:stdout_out] << oe[:stdout_in] if oe[:stdout_in] && oe[:stdout_out]
    end

    # Normalizes the opts so that we can accept opts from pretty much
    # anywhere (run, and others.)

    def normalize_opts(opts = {})
      opts[:timeout] = @timeout unless opts.has_key?(:timeout)
      opts[:capture_exit_status] = @capture_exit_status unless \
        opts.has_key?(:capture_exit_status)
      opts
    end

    # Allows you to see the +#to_s+ as "user@hostname" so that you can always
    # run +#to_s+ and go back to the primitive form.

    def to_s
      "#{@username}@#{@hostname}"
    end

    # A more elegent viewing of the inspection that keeps stuff from folding
    # over when debugging inside of pry and stuff like that.

    def inspect
      "<#{self.class} @host = #{@hostname}, @user = #{@username}>"
    end

    # Raise an error if there is a bad exit status.

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
