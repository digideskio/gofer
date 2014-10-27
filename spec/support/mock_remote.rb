class MockRemote < Gofer::Remote
  def initialize
    super "mock", "mock"
  end

  def run(cmd, opts)
    opts = normalize_opts(opts)
    debug = debug = Gofer::Debug.new(cmd, opts, opts[:env], self)
    cmd = set_pwd_on_cmd(cmd, opts[:env])
    cmd = set_env_on_cmd(cmd, opts[:env])

    debug.cmd = cmd
    debug.response = Gofer::Response.new("", "", "", 0)
    debug
  end
end
