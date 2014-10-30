require "gofer/error"
require "forwardable"
require "gofer/response"
require "gofer/debug"
require "gofer/base"
require "open3"

module Gofer
  class Local < Base
    extend Forwardable

    def_delegator :File, :read

    def initialize(opts = {})
      @username = ENV["USER"]
      @hostname = "localhost"
      super
    end

    def write(data, to)
      file = File.open(to, "w+")
      file.write(data)
      nil
    ensure
      file.close
    end

    def run(cmd, opts = {})
      opts = normalize_opts(opts)
      debug = Debug.new(cmd, opts, opts[:env], self)
      cmd = set_pwd_on_cmd(cmd, opts[:env])

      debug.cmd = cmd
      with_timeout(opts[:timeout]) { debug.response = with_open3(cmd, opts, "", "", "") }
      debug.raise_if_asked
    end

    private
    def with_open3(cmd, opts, stdout, stderr, combined)
      exit_status = 0

      Open3.popen3(opts[:env], cmd) do |input, out, err, wait|
        input.puts(opts[:stdin]) if opts[:stdin]
        input.close

        while data = out.gets do stdout, combined = write_stdout(data, opts, stdout, combined) end
        while data = err.gets do stderr, combined = write_stderr(data, opts, stderr, combined) end
        exit_status = wait.value.exitstatus if ! wait.value.success?
      end

      return [
        stdout,
        stderr,
        combined,
        exit_status
      ]
    end
  end
end
