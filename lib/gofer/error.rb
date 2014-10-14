module Gofer
  class Error < StandardError
    attr_reader :response, :host, :command

    def initialize(host, response, command)
      @command = command
      @response = response
      @host = host

      # Because realistically this the only error we ever experience....
      super("#{@host.hostname}: Command #{@command} failed with bad exit #{@response.exit_status}")
    end
  end
end
