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
      exit_status = 0
      stdout = ""
      stderr = ""
      output = ""

      opts = normalize_opts(opts)
      debug = debug = Debug.new(cmd, opts, opts[:env], self)
      cmd = set_pwd_on_cmd(cmd, opts[:env])
      cmd = set_env_on_cmd(cmd, opts[:env])

      ssh.open_channel do |channel|
        channel.exec(cmd) do |_, s|
          raise "SSH Channnel: Couldn't execute command #{cmd}" unless s

          channel.on_extended_data do |_, type, data|
            next unless type == 1
            write_stdio(:stderr, {
              :output => output,
              :opts => opts,
              :stderr => {
                :in => data,
                :out => stderr
              }
            })
          end

          channel.on_data do |_, data|
            write_stdio(:stdout, {
              :output => output,
              :opts => opts,
              :stdout => {
                :in => data,
                :out => stdout
              }
            })
          end

          channel.on_request("exit-status") do |_, data|
            exit_status = data.read_long
            channel.close
          end

          if opts[:stdin]
            channel.send_data(opts[:stdin])
            channel.eof!
          end
        end
      end

      ssh.loop
      debug.cmd = cmd
      debug.response = Gofer::Response.new(stdout, stderr, output, exit_status)
      debug.raise_if_asked
    end

    # TODO: ->
    #   I don't think this does what I think it does because that would
    #   make no sense whatsoever if it did, but I guess I'll have to edge
    #   test it to find out.

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
  end
end
