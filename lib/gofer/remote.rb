require "net/ssh"
require "tempfile"
require "gofer/base"
require "gofer/response"
require "gofer/error"
require "net/scp"

module Gofer
  class Remote < Base
    attr_accessor :hostname, :username, :ssh, :scp, :stdio

    def initialize(hostname, username, opts = {})
      super(opts) # It's destructive to opts.

      @hostname, @username = hostname, username
      @ssh = Net::SSH.start(@hostname, @username, opts)
      @scp = Net::SCP.new(@ssh)
    end

    # Run +command+. Will raise an error if +command+ exits with a non-zero
    # status, unless +capture_exit_status+ is true.

    def run(command, opts = {})
      out = ssh_execute(command, opts = normalize_opts(opts))
      if ! opts[:capture_exit_status] && out.exit_status != 0
        raise Error.new(self, out, \
          "Command #{command} failed with exit status #{out.exit_status}")
      end

    out
    end

    # Download a file from SSH.

    def read(path)
      scp.download!(
        path
      )
    end

    # Write data to a file.

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

    # Alias a few acceptable methods.

    [:download, :upload].each do |k|
      define_method k do |f, t, o = {}|
        scp.send("#{k}!", f, t, o.merge(recursive: File.directory?(f)))
      end
    end

    # If opts[:stdout] and opts[:stderr] are passed we call your method on a
    # streaming basis so you can do "live output" with alterations if you want
    # otherwise we just shove it out if you want us to and then handle it.

    private
    def ssh_execute(command, opts = {})
      exit_status = 0
      stdout = ""
      stderr = ""
      output = ""

      opts = normalize_opts(opts)
      @ssh.open_channel do |c|
        c.exec(command) do |_, s|
          raise "SSH Channnel: Couldn't execute command #{command}" unless s

          c.on_extended_data do |_, t, d|
            next unless t == 1
            write_stdio({
              :opts => opts,
              :stderr_in => d,
              :stderr_out => stderr,
              :output => output
            })
          end

          c.on_data do |_, d|
            write_stdio({
              :stdout_in => d,
              :stdout_out => stdout,
              :output => output,
              :opts => opts
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

      @ssh.loop
      Gofer::Response.new(stdout, stderr, output, exit_status)
    end
  end
end
