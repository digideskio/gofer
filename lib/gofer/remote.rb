require "gofer/helpers/stdio"
require "gofer/extensions/hash"
require "gofer/response"
require "gofer/debug"
require "gofer/base"
require "gofer/error"

require "shellwords"
require "net/ssh"
require "tempfile"
require "net/scp"

module Gofer
  class Remote < Base
    def initialize(hostname, username, opts = {})
      @hostname = hostname
      @username = username
      super opts
    end

    def ssh
      @ssh ||= Net::SSH.start(@hostname, @username, @ssh_opts)
    end

    def scp
      @scp ||= Net::SCP.new(ssh)
    end

    def run(cmd, opts = {})
      opts = normalize_opts(opts)
      debug = Debug.new(cmd, opts, opts[:env], self)
      cmd = set_pwd_on_cmd(cmd, opts[:env])
      cmd = set_env_on_cmd(cmd, opts[:env])

      debug.cmd = cmd
      with_timeout(opts[:timeout]) { debug.response = ssh_channel(cmd, opts) }
      debug.raise_if_asked
    end

    def read(path)
      scp.download!(path)
    end

    def write(data, to)
      tmpfile = Tempfile.open("gofer_write")
      tmpfile.write(data)
      tmpfile.flush

      upload(tmpfile.path, to)
    ensure
      tmpfile.close
      tmpfile.unlink
    end

    [:download, :upload].map do |k|
      define_method k do |f, t, o = {}|
        scp.send("#{k}!", f, t, o.merge(:recursive => File.directory?(f)))
      end
    end

    private
    def ssh_channel(cmd, opts, stdout = "", stderr = "", combined = "")
      exit_status = 0

      ssh.open_channel do |channel|
        channel.exec(cmd) do |_, success|
          raise "Couldn't execute command #{cmd}" unless success
          channel.send_data(opts[:stdin]) if opts[:stdin]
          channel.eof!

          channel.on_data { |_, data| stdout, combined = write_stdout(data, opts, stdout, combined) }
          channel.on_extended_data { |_, type, data| stderr, combined = write_stderr(data, opts, stderr, combined) }
          channel.on_request("exit-status") { |_, data| exit_status = data.read_long }
        end
      end

      ssh.loop
      return [
        stdout,
        stderr,
        combined,
        exit_status
      ]
    end
  end
end
