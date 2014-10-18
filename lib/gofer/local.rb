require "gofer/error"
require "gofer/response"
require "gofer/base"
require "open3"

module Gofer
  class Local < Base
    def initialize(opts = {})
      @username, @hostname = ENV["USER"], "localhost"
      super
    end

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
