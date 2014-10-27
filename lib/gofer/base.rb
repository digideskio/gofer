require "timeout"

module Gofer
  class Base
    KNOWN_OPTS = [ :capture_exit_status, :env, :timeout, :stdio ]
    attr_reader :hostname, :username

    def initialize(opts = {})
      @capture_exit_status = opts[:capture_exit_status]
      @stdio_class = opts[:stdio] || Helpers::Stdio
      @timeout = opts[:timeout] || 12
      @env = opts[:env] || {}

      set_ssh_opts(opts)
      set_stdio_opts(opts)
    end

    def to_s
      "#{@username}@#{@hostname}"
    end

    def inspect
      %Q{<#{self.class} "#{@username}@#{@hostname}">}
    end

    private
    def with_timeout(timeout)
      # So you can set 0 and below to kick on notime.
      if timeout.nil? || timeout.blank? || 1 > timeout
        yield
      else
        Timeout.timeout(timeout) do
          yield
        end
      end
    end

    private
    def set_ssh_opts(opts)
      @ssh_opts = opts.inject({}) do |hash, (key, value)|
        unless Helpers::Stdio::KNOWN_OPTS.include?(key) || KNOWN_OPTS.include?(key)
          hash[key] = value
        end

        hash
      end
    end

    private
    def set_stdio_opts(opts)
      @stdio_opts = Helpers::Stdio::KNOWN_OPTS.inject({}) do |hash, key|
        hash[key] = opts[key] if opts[key]
        hash
      end
    end

    # Because a lot of servers don't have AcceptEnv past LC_* there is no
    # reason to ever rely on +Net::SSH+ to send the environment, just send it
    # by attaching it as an export on each command.

    private
    def set_env_on_cmd(cmd, env)
      return cmd if env.empty?
      env.each do |k, v|
        cmd = "export #{k}=#{Shellwords.shellescape(v)}; #{cmd}"
      end

      cmd
    end

    private
    def set_pwd_on_cmd(cmd, env = {})
      if env.has_key?("PWD") && ! env["PWD"].nil? && ! env["PWD"].empty?
        cmd = "cd #{Shellwords.shellescape(env["PWD"])} && #{cmd}"
      end
    cmd
    end

    private
    def normalize_opts(opts = {})
      opts[:env] = (opts[:env] || {}).stringize
      opts.dup.merge_if!({
        :timeout => @timeout,
        :capture_exit_status => @capture_exit_status
      })
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
    def stdio
      @stdio ||= @stdio_class.new(@stdio_opts)
    end
  end
end
