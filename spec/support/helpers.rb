require "fileutils"
require "tmpdir"

# Provides a class for us to test the :stdio => Stdio option in +Gofer::Local+,
# and +Gofer::Remote+ making sure that they work.

class TempStdio < Gofer::Stdio
  def stdout(line, opts)
    normalize_opts(opts)

    if opts.size > 0
      stringio.write(line)
    end
  end

  def stringio
    @stringio ||= StringIO.new
  end
end

module IntegrationHelpers

  # Create a temp file (this file must be used within +#with_temp+ or it will
  # fail... unless you provide a +@tmpdir+ ivar.)

  def create_tmpfile(file, val = nil)
    file = FileUtils.touch(@tmpdir.join(file)).first
    File.write(file, val) if val
    file
  end

  # Creates a tmpdir so you can start doing what you need with tmpfiles in that
  # tmpdir... Ensures that it is removed but sometimes if you exit! in pry
  # it will not remove them so it makes no matter in that case.

  def with_tmp(&block)
    @tmpdir = Pathname.new(Dir.mktmpdir("gofertest"))
    yield
  ensure
    FileUtils.remove_entry_secure @tmpdir, \
      force: true, recursive: true
    @tmpdir = nil
  end
end
