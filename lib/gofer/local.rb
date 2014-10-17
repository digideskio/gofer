require "gofer/error"
require "gofer/response"
require "gofer/base"
require "open3"

module Gofer
  class Local < Base

    # Open up a class that runs commands locally using +Open3.popen3+ unlike
    # the other classes if there are opts we don't know then they are ignored
    # and not even used but we accept the same base.
    #
    # @opt opts quiet Whether or not to raise or pass the exit status.
    # @opt opts output_prefix the prefix to output each line of stdout with.

    def initialize(opts = {})
      @username, @hostname = ENV["USER"], "localhost"
      super
    end

    # Run the command using +Open3.popen3+

    def run(command, opts = {})
      exit_status = 0
      stdout = ""
      stderr = ""
      output = ""

      opts = normalize_opts(opts)
      Open3.popen3(command) do |i, o, e, t|
        if opts[:stdin]
          i.puts opts[:stdin]
        end

        i.close
        while line = o.gets do
          write_stdio({
            :opts => opts,
            :stdout_in => line,
            :stdout_out => stdout,
            :output => output
          })
        end

        while line = e.gets do
          write_stdio({
            :opts => opts,
            :stderr_in => line,
            :stderr_out => stderr,
            :output => output
          })
        end

        if ! t.value.success?
          exit_status = t.value.exitstatus
        end
      end

      # Just mock out what Gofer normally mocks out.
      out = Gofer::Response.new(stdout, stderr, output, exit_status)
      raise_if_bad_exit(command, out, opts)
    out
    end
  end
end
