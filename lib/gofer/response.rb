class Gofer::Response < String
  attr_reader :stdout, :stderr, :combined, :exit_status

  def initialize(stdout, stderr, combined, exit_status)
    @stdout = stdout
    @combined = combined
    @exit_status = exit_status
    @stderr = stderr

    super @stdout
  end
end
