require "open3"

module Gofer
  class Local
    attr_accessor :quiet, :output_prefix
    attr_reader   :hostname, :username
    include OutputHandlers, Helpers

    def initialize(opts = {})
      @hostname, @username = "localhost", ENV["USER"]
      @quiet, @output_prefix = opts.delete(:quiet), opts.delete(:output_prefix)
      @at_start_of_line = true
    end

    def run(command, opts = {})
      opts[:quiet] = quiet unless opts.has_key?(:quiet)
      stdout, stderr, output, exit_status = "", "", "", 0
      opts[:output_prefix] ||= output_prefix
      opts[:stdout] ||= method(:stdout)
      opts[:stderr] ||= method(:stderr)

      Open3.popen3(command) do |i, o, e, t|
        if opts[:stdin]
          i.puts opts[:stdin]
        end

        i.close
        while line = o.gets do
          opts[:stdout].call(
            line, opts
          )

          stdout += line
          output += line
        end

        while line = e.gets do
          opts[:stderr].call(
            line, opts
          )

          stderr += line
          output += line
        end

        if ! t.value.success?
          exit_status = t.value.exitstatus
        end
      end

      # Just mock out what Gofer normally mocks out.
      out = Gofer::Response.new(stdout, stderr, output, exit_status)
      if ! opts[:capture_exit_status] && out.exit_status != 0
        raise HostError.new(
          self, out, "Command #{command} failed with exit status #{out.exit_status}"
        )
      end
    out
    end
  end
end
