require 'tempfile'

module Gofer
  include Helpers

  # ---------------------------------------------------------------------------
  # A persistent, authenticated SSH connection to a single host.
  #
  # Connections are persistent, but not encapsulated within a shell. This means
  # that while it won't need to reconnect & re-authenticate for each operation,
  # don't assume that environment variables will be persisted between commands
  # like they will in a shell-based SSH session.
  # ---------------------------------------------------------------------------

  class Host
    attr_accessor :quiet, :output_prefix
    attr_reader   :hostname, :username

    # -------------------------------------------------------------------------
    # Create a new connection to a host
    #
    # Passed options not included in the below are passed directly to
    # <tt>Net::SSH.start</tt>. See http://net-ssh.github.com/ssh/v2/api/index.html
    # for valid arguments.
    #
    # @param opts [Hash] The options hash (@see @option)
    # @option :quiet [true, false] whether or not to print directly to your FD.
    # @opt :output_prefix [String] Add a prefix to each line of the returned out.
    # -------------------------------------------------------------------------

    def initialize(hostname, username, opts = {})
      @quiet, @output_prefix = opts.delete(:quiet), opts.delete(:output_prefix)
      @hostname, @username = hostname, username
      @ssh = SshWrapper.new(
        @hostname, @username, opts
      )
    end

    # -------------------------------------------------------------------------
    # Run +command+. Will raise an error if +command+ exits with a non-zero
    # status, unless +capture_exit_status+ is true.
    #
    # Print +stdout+ and +stderr+ as they're received.
    # @param opts [Hash] the options (@see @options)
    # @option :quiet [true, false] whether or not to print directly to your FD.
    # @option :quiet_stderr [true, false] whether to print stderrss to your FD.
    # @option :capture_exit_status [true, false] raise or not on non-zero exit.
    # @option :stdin [String] send something straight to stdin and get results.
    # @return   Gofer::Response an encapsulated result of stdout, stderr, exit.
    # -------------------------------------------------------------------------

    def run(command, opts = {})
      opts[:quiet] = quiet unless opts.has_key?(:quiet)
      opts[:output_prefix] ||= output_prefix

      out = @ssh.run(command, opts)
      if ! opts[:capture_exit_status] && out.exit_status != 0
        raise HostError.new(
          self, out, "Command #{command} failed with exit status #{@ssh.last_exit_status}"
        )
      end

      out
    end

    # -------------------------------------------------------------------------
    # Returns +true+ if +path+ exists, +false+ otherwise.
    # -------------------------------------------------------------------------

    def exist?(path)
      @ssh.run("sh -c '[ -e #{path} ]'").exit_status == 0
    end

    # -------------------------------------------------------------------------
    # Returns the contents of the file at +path+.
    # -------------------------------------------------------------------------

    def read(path)
      @ssh.read_file(path)
    end

    # -------------------------------------------------------------------------
    # Returns +true+ if +path+ is a directory, +false+ otherwise.
    # -------------------------------------------------------------------------

    def directory?(path)
      @ssh.run("sh -c '[ -d #{path} ]'").exit_status == 0
    end

    # -------------------------------------------------------------------------
    # Returns a list of the files in the directory at +path+.
    # -------------------------------------------------------------------------

    def ls(path)
      out = @ssh.run("ls -1 #{path}", :quiet => true)
      if out.exit_status == 0
        then out.stdout.strip.each_line.to_a
        else raise HostError.new(
          self, out, "Could not list #{path}, exit status #{out.exit_status}"
        )
      end
    end

    # -------------------------------------------------------------------------
    # Uploads the file or directory at +from+ to +to+.
    # -------------------------------------------------------------------------

    def upload(from, to, opts = {})
      @ssh.upload(from, to, { recursive: File.directory?(from) }.merge(opts))
    end

    # -------------------------------------------------------------------------
    # Downloads the file or directory at +from+ to +to+
    # -------------------------------------------------------------------------

    def download(from, to, opts = {})
      @ssh.download from, to, { recursive: directory?(from) }.merge(opts)
    end

    # -------------------------------------------------------------------------
    # Writes +data+ to a file at +to+
    # -------------------------------------------------------------------------

    def write(data, to)
      tmpfile = Tempfile.open("gofer_write")
      tmpfile.write(data) and tmpfile.flush
      @ssh.upload(tmpfile.path, to, recursive: false)
    ensure
      tmpfile.close
      tmpfile.unlink
    end
  end
end
