class Gofer::Response < String
  attr_reader :stdout, :stderr, :output, :exit_status

  def initialize(stdout, stderr, output, exit_status)
    @exit_status = exit_status
    @stdout = stdout
    @stderr = stderr
    @output = output
    super @stdout
  end
end
