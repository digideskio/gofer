require "fileutils"
require "tmpdir"

module IntegrationHelpers
  def create_tmpfile(file, val = nil)
    file = FileUtils.touch(@tmpdir.join(file)).first
    File.write(file, val) if val
    file
  end

  def with_tmp(&block)
    @tmpdir = Pathname.new(Dir.mktmpdir("gofertest"))
    yield
  ensure
    @tmpdir = FileUtils.remove_entry_secure @tmpdir, \
      force: true, recursive: true
  end

  def with_captured_output
    @stdout, @stderr, @combined = "", "", ""
    allow($stdout).to receive(:write) { |*a| @stdout.<<(*a); @combined.<<(*a) }
    allow($stderr).to receive(:write) { |*a| @stderr.<<(*a); @combined.<<(*a) }
    yield
  ensure
    [:@stdout, :@stderr, :@combined].each do |v|
      remove_instance_variable v
    end
  end
end
