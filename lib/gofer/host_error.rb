module Gofer

  # ---------------------------------------------------------------------------
  # An error encountered performing a Gofer command.
  # ---------------------------------------------------------------------------

  class HostError < Exception
    attr_reader :response, :host

    def initialize(host, response, message)
      @host, @response = host, response
      super("#{host.hostname}: #{message}")
    end
  end
end
