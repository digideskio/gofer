module Gofer
  class Base
    attr_reader :stdio

    def initialize(opts = {})
      @capture_exit_status = opts.delete(:capture_exit_status)

      quiet_stdout = opts.delete(:quiet_stdout)
      output_prefix = opts.delete(:output_prefix)
      quiet_stderr = opts.delete(:quiet_stderr)
      stdout = opts[:stdout] || $stdout
      stderr = opts[:stderr] || $stderr

      @stdio = (opts.delete(:stdio) || Stdio).new({
        :stderr => stderr,
        :quiet_stderr => quiet_stderr,
        :output_prefix => output_prefix,
        :quiet_stdout => quiet_stdout,
        :stdout => stdout,
      })
    end

    # A wrapper that de-duplicates stuff to write to Stdio.

    def write_stdio(oe = {})
      oe[:output] << oe[:stderr_in] if oe[:stderr_in]
      oe[:output] << oe[:stdout_in] if oe[:stdout_in]
      @stdio.stderr(oe[:stderr_in], oe[:opts]) if oe[:stderr_in]
      @stdio.stdout(oe[:stdout_in], oe[:opts]) if oe[:stdout_in]
      oe[:stderr_out] << oe[:stderr_in] if oe[:stderr_in] && oe[:stderr_out]
      oe[:stdout_out] << oe[:stdout_in] if oe[:stdout_in] && oe[:stdout_out]
    end

    # Normalizes the opts so that we can accept opts from pretty much
    # anywhere (run, and others.)

    def normalize_opts(opt = {})
      opt[:timeout] = @timeout unless opt.has_key?(:timeout)
      opt[:capture_exit_status] = @capture_exit_status unless \
        opt.has_key?(:capture_exit_status)
    opt
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
  end
end
