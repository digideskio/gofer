class Gofer::Response < String
  attr_reader :stdout, :stderr, :combination, :exit_status

  def initialize(stdout, stderr, combination, exit_status)
    @stdout = stdout
    @combination = combination
    @exit_status = exit_status
    @stderr = stderr

    super @stdout
  end
end
