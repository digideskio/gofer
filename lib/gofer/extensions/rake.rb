require "rake/task"

module Rake
  class << self
    attr_accessor :current_task
  end

  class Task

    # Override execute so I can access the current rake task from the deployer.
    # This is so that I can track where a task fails instantly if I need to do
    # some minor debugging in the application layer.  It's also output to you
    # when the deployer is doing it's own work for your.

    @@__old_execute_0xa5df = instance_method(:execute)
    def execute(*args)
      Rake.current_task = @name
      rtn = @@__old_execute_0xa5df.bind(self).call(*args)
      Rake.current_task = nil
      rtn
    end
  end
end
