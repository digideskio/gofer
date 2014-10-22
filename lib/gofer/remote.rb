require "net/ssh"
require "tempfile"
require "gofer/base"
require "gofer/response"
require "gofer/error"
require "net/scp"

module Gofer
  class Remote < Base
    def initialize(hostname, username, opts = {})
      @hostname, @username = hostname, username
      super(opts)
    end

    def ssh
      @ssh ||= Net::SSH.start(
        @hostname, @username, @ssh_opts
      )
    end

    def scp
      @scp ||= Net::SCP.new(
        ssh
      )
    end

    def run(command, opts = {})
      out = ssh_execute(command, opts = normalize_opts(opts))
      raise_if_bad_exit(command, out, opts)
    out
    end

    def read(path)
      scp.download!(
        path
      )
    end

    def write(data, to)
      tmpfile = Tempfile.open("gofer_write")
      tmpfile.write(data)
      tmpfile.flush

      upload(tmpfile.path, to)
    ensure
      [:close, :unlink].map do |k|
        tmpfile.send(k)
      end
    end

    [:download, :upload].each do |k|
      define_method k do |f, t, o = {}|
        scp.send("#{k}!", f, t, o.merge(:recursive => File.directory?(f)))
      end
    end

    # Because a lot of servers don't have AcceptEnv past LC_* there is no
    # reason to ever rely on +Net::SSH+ to send the environment, just send it
    # by attaching it as an export on each command.

    private
    def build_env(cmd, env)
      return cmd if env.empty?
      env.each do |k, v|
        cmd = cmd.prepend(%Q{export #{k}=#{Shellwords.shellescape(v)}; })
      end
    cmd
    end

    private
    def ssh_execute(cmd, opts = {})
      opts = normalize_opts(opts)
      exit_status = 0
      stdout = ""
      stderr = ""
      output = ""

      cmd = build_env(attach_cd(cmd, opts[:env]), opts[:env])
      ssh.open_channel do |c|
        c.exec(cmd) do |_, s|
          raise "SSH Channnel: Couldn't execute command #{command}" unless s

          c.on_extended_data do |_, t, d|
            next unless t == 1
            write_stderr({
              :output => output,
              :opts => opts,
              :stderr => {
                :in => d,
                :out => stderr
              }
            })
          end

          c.on_data do |_, d|
            write_stdout({
              :output => output,
              :opts => opts,
              :stdout => {
                :in => d,
                :out => stdout
              }
            })
          end

          c.on_request("exit-status") do |_, d|
            exit_status = d.read_long
            c.close
          end

          if opts[:stdin]
            c.send_data(opts[:stdin])
            c.eof!
          end
        end
      end

      ssh.loop
      Gofer::Response.new(stdout, stderr, output, exit_status)
    end
  end
end
