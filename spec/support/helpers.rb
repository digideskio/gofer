require "fileutils"
require "tmpdir"

class TempStdio < Gofer::Helpers::Stdio
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

class TmpTmp
  attr_reader :tmpdir

  def initialize
    @tmpdir = Pathname.new(
      Dir.mktmpdir("gofertest")
    )
  end

  # Create a tempfile in the tmpdir.

  def create_tmpfile(file, val = nil)
    file = FileUtils.touch(@tmpdir.join(file)).first
    File.write(file, val) if val
    file
  end

  # Destroy the tmpdir.

  def destroy
    FileUtils.remove_entry_secure @tmpdir, \
      force: true, recursive: true
  end
end

module IntegrationHelpers
  def with_tmp(&block)
    block.call(tmptmp = TmpTmp.new)
  ensure
    # Ensure.
    tmptmp.destroy
  end
end
