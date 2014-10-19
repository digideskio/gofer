module Gofer
  class Response < String
    attr_reader :stdout, :stderr, :output, :exit_status
    def initialize(stdout, stderr, output, exit_status)
      super @stdout = stdout and (
        @stderr, @output, @exit_status = stderr, output, exit_status
      )
    end
  end
end
