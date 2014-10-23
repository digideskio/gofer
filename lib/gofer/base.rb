module Gofer
  class Base
    KNOWN_OPTS = [ :capture_exit_status, :env, :timeout, :stdio ]
    attr_reader :hostname, :username

    def initialize(opts = {})
      @capture_exit_status = opts[:capture_exit_status]
      @stdio_class = opts[:stdio] || Helpers::Stdio
      @timeout = opts[:timeout] || 12
      @env = opts[:env] || {}

      create_ssh_opts(opts)
      create_stdio_opts(opts)
    end

    # write_stdout, write_stderr
    [:stderr, :stdout].each do |key|
      define_method "write_#{key}" do |str|
        write_stdio(key, str)
      end
    end

    def to_s
      "#{@username}@#{@hostname}"
    end

    def inspect
      %Q{<#{self.class} "#{@username}@#{@hostname}">}
    end

    private
    def create_ssh_opts(opts)
      @ssh_opts = opts.dup.delete_if do |key, value|
        Helpers::Stdio::KNOWN_OPTS.include?(key) || KNOWN_OPTS.include?(key)
      end
    end

    private
    def create_stdio_opts(opts)
      @stdio_opts = Helpers::Stdio::KNOWN_OPTS.inject({}) do |hash, key|
        hash[key] = opts[key]
        hash
      end
    end

    private
    def attach_cd(cmd, env = {})
      if env.has_key?("PWD") && ! env["PWD"].nil? && ! env["PWD"].empty?
        cmd = "cd #{Shellwords.shellescape(env["PWD"])} && #{cmd}"
      end
    cmd
    end

    private
    def normalize_opts(opts = {})
      opts[:env] = (opts[:env] || {}).stringize
      opts.merge_if!({
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
