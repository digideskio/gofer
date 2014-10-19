module Gofer
  class Base
    attr_reader :hostname, :username
    KNOWN_OPTS = [
      :capture_exit_status, :env, :timeout, :stdio
    ]

    def initialize(opts = {})
      @capture_exit_status = opts[:capture_exit_status]
      @stdio_class, @stdio_opts = opts[:stdio] || Stdio, {}
      @timeout = opts[:timeout] || 12
      @env = opts[:env] || {}

      Stdio::KNOWN_OPTS.each { |k| @stdio_opts[k] = opts[k] }
      @ssh_opts = opts.delete_if { |k, v| Stdio::KNOWN_OPTS.include?(k) || KNOWN_OPTS.include?(k) }
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
    def attach_cd(cmd, env = {})
      if env.has_key?("PWD")
        cmd = cmd.prepend(%Q{cd #{Shellwords.shellescape(env["PWD"])} && })
      end
    cmd
    end

    private
    def normalize_opts(opts = {})
      opts = opts.merge_if(:capture_exit_status => @capture_exit_status, :timeout => @timeout)
      opts[:env] = @env.merge(opts[:env] || {}).inject({}) do |h, (k, v)|
        h.update(k.to_s => v.to_s)
      end
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
