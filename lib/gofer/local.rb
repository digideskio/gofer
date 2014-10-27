require "gofer/error"
require "gofer/response"
require "gofer/debug"
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
      debug = Debug.new(cmd, opts, opts[:env], self)
      cmd = set_pwd_on_cmd(cmd, opts[:env])

      Open3.popen3(opts[:env], cmd) do |_in, out, err, wait|
        if opts[:stdin]
          _in.puts opts[:stdin]
        end

        _in.close
        while line = out.gets do
          write_stdio(:stdout, {
            :output => output,
            :opts => opts,
            :stdout => {
              :in => line,
              :out => stdout
            }
          })
        end

        while line = err.gets do
          write_stdio(:stderr, {
            :output => output,
            :opts => opts,
            :stderr => {
              :in => line,
              :out => stderr
            }
          })
        end

        if ! wait.value.success?
          exit_status = wait.value.exitstatus
        end
      end

      debug.cmd = cmd
      debug.response = Gofer::Response.new(stdout, stderr, output, exit_status)
      debug.raise_if_asked
    end
  end
end
