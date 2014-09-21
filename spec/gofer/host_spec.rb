require "spec_helper"
require "tempfile"

describe Gofer::Host do
  before :all do
    @host = Gofer::Host.new("127.0.0.1", ENV["USER"], :quiet => true)
  end

  specify "#hostname == connected hostname" do
    expect(@host.hostname).to eq "127.0.0.1"
  end

  describe :run do
    describe "with stdout and stderr responses" do
      before :all do
        @response = @host.run("echo stdout; echo stderr 1>&2", {
          :quiet_stderr => true
        })
      end

      it("captures stderr") { expect(@response.stderr.strip).to eq "stderr" }
      specify("have a combination output")  {  expect(@response.output.strip).to eq "stdout\nstderr" }
      specify("behave like a string and default to stdout") { expect(@response.strip).to eq "stdout" }
      it("captures stdout") { expect(@response.stdout.strip).to eq "stdout" }
    end

    it "prints responses unless quiet is true" do
      expect($stdout).to receive(:write).with "stdout\n"
      @host.run "echo stdout", :quiet => false
    end

    it "prints stderr responses unless quiet_stderr is true" do
      expect($stderr).to receive(:write).with "stderr\n"
      @host.run "echo stderr 1>&2", :quiet_stderr => false
    end

    context "with a host output prefix" do
      before(:all) { @host.output_prefix = "derp" }
      after (:all) { @host.output_prefix = nil    }

      specify "prefix first line of stdout and stderr" do
        with_captured_output do
          @host.run "echo stdout; echo stdout2; echo stderr 1>&2; echo stderr2 1>&2", {
            :quiet => false, :quiet_stderr => false
          }

          expect(@stdout.strip).to eq "derp: stdout\nderp: stdout2"
          expect(@stderr.strip).to eq "derp: stderr\nderp: stderr2"
        end
      end

      specify "don't prefix continued output on new lines" do
        with_captured_output do
          @host.run "echo -n foo; echo bar; echo baz; ", :quiet => false
          expect(@combined.strip).to eq "derp: foobar\nderp: baz"
        end
      end
    end

    specify "process stdin when stdin is set" do
      with_captured_output do
        @host.run "sed 's/foo/baz/'", :stdin => "foobar", :quiet => false
        expect(@stdout.strip).to eq "bazbar"
      end
    end

    specify "raise if command returns a non-zero" do
      begin  @host.run "false"; rescue Gofer::HostError => e
        expect(e).to be_kind_of Gofer::HostError
        expect(e.host).to be_kind_of Gofer::Host
        expect(e.message).to match(/failed with exit status/)
      end
    end

    specify "capture a non-zero exit status if told" do
      response = @host.run("false", :capture_exit_status => true)
      expect(response.exit_status).to eq 1
    end
  end

  describe :exist? do
    specify "return true if path exists" do
      with_tmp do
        expect(@host.exist?(create_tmpfile("exists"))).to eq true
      end
    end

    specify "return false if path doesn't exist" do
      expect(@host.exist?(File.join("/tmp", SecureRandom.hex))).to eq false
    end
  end

  describe :directory? do
    specify "return true if dir exists" do
      with_tmp do
        expect(@host.directory?(@tmpdir)).to eq true
      end
    end

    specify "return false if dir doesn't exist" do
      with_tmp do
        expect(@host.directory?(create_tmpfile("exists"))).to eq false
      end
    end
  end

  describe :read do
    it "reads the contents of a file" do
      with_tmp do
        expect(@host.read(create_tmpfile("hello", "hello\nworld")).strip).to eq "hello\nworld"
      end
    end
  end

  describe :ls do
    it "lists the contents of a dir" do
      with_tmp do
        expect(@host.ls(File.dirname(create_tmpfile("lstmp")))).to eq ["lstmp"]
      end
    end
  end

  describe :uploads do
    specify "files" do
      with_tmp do
        client_file = create_tmpfile("hello", "hello")
        server_file = @tmpdir.join("world")
        @host.upload(client_file, server_file)
        expect(server_file.file?).to eq true
        expect(server_file.read.strip).to eq "hello"
      end
    end

    specify "directories" do
      with_tmp do
        ogfolder = FileUtils.mkdir(@tmpdir.join("hello")).first
        file = @tmpdir.join("world/world")
        create_tmpfile("hello/world", "hello")
        folder = @tmpdir.join("world")

        @host.upload(ogfolder, folder)
        expect(file.file?).to eq true
        expect(File.directory?(@tmpdir.join("world"))).to eq true
        expect(file.read.strip).to eq "hello"
      end
    end
  end

  describe :writes do
    specify "files" do
      with_tmp do
        file = @tmpdir.join("hello")
        @host.write("world", file)
        expect(file.file?).to eq true
        expect(file.read.strip).to eq "world"
      end
    end
  end

  describe :downloads do
    specify "files" do
      with_tmp do
        server_file = create_tmpfile("hello", "hello")
        client_file = @tmpdir.join("world")
        @host.download(server_file, client_file)
        expect(client_file.file?).to eq true
        expect(client_file.read.strip).to eq "hello"
      end
    end

    specify "directories" do
      with_tmp do
        client_file = @tmpdir.join("world/hello/world")
        server_folder = FileUtils.mkdir(@tmpdir.join("hello")).first
        client_base_folder = @tmpdir.join("world").to_s
        client_folder = @tmpdir.join("world/hello")
        create_tmpfile("hello/world", "hello")

        @host.download(server_folder, client_base_folder)
        expect(client_folder.directory?).to eq true
        expect(client_file.file?).to eq true
        expect(client_file.read.strip).to eq "hello"
      end
    end
  end
end
