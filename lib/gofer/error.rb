module Gofer
  class Error < StandardError
    attr_reader :response, :host, :command

    def initialize(host, response, command)
      @command = command
      @response = response
      @host = host

      super("command #{@command} exited with #{@response.exit_status}")
    end
  end
end
