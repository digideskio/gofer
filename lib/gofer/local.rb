require "gofer/error"
require "gofer/response"
require "gofer/base"
require "open3"

module Gofer
  class Local < Base
    def initialize(opts = {})
      @username = ENV["USER"]
      @hostname = "localhost"
      super
    end

    def run(cmd, opts = {})
      exit_status = 0
      stdout = ""
      stderr = ""
      output = ""

      opts = normalize_opts(opts)
      # TODO: Expand the single letter variables when you have time.
      Open3.popen3(opts[:env], attach_cd(cmd, opts[:env])) do |i, o, e, t|
        if opts[:stdin]
          i.puts opts[:stdin]
        end

        i.close
        while line = o.gets do
          write_stdout({
            :output => output,
            :opts => opts,
            :stdout => {
              :in => line,
              :out => stdout
            }
          })
        end

        while line = e.gets do
          write_stderr({
            :output => output,
            :opts => opts,
            :stderr => {
              :in => line,
              :out => stderr
            }
          })
        end

        if ! t.value.success?
          exit_status = t.value.exitstatus
        end
      end

      # Just mock out what Gofer normally mocks out.
      out = Gofer::Response.new(stdout, stderr, output, exit_status)
      raise_if_bad_exit(cmd, out, opts)
    out
    end
  end
end
