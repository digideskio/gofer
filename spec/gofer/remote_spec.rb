require "rspec/helper"

describe Gofer::Remote do
  before :all do
    @host = Gofer::Remote.new("127.0.0.1", ENV["USER"], {
      :quiet => true
    })
  end

  specify("#hostname == connected hostname") { expect(@host.hostname).to eq "127.0.0.1" }
  specify("#username == connected username") { expect(@host.username).to eq ENV["USER"] }
  specify("#to_s == user@host") { expect(@host.to_s).to eq "#{ENV["USER"]}@127.0.0.1"   }

  specify "#inspect" do
    expect(@host.inspect).to eq "<Gofer::Remote @host = 127.0.0.1, @user = #{ENV["USER"]}>"
  end

  specify "accept custom stdio" do
    host = Gofer::Remote.new("127.0.0.1", ENV["USER"], {
      :stdio => TempStdio
    })

    host.run("echo hello")
    expect(host.stdio).to be_kind_of TempStdio
    expect(host.stdio.stringio.string.strip).to eq "hello"
  end

  describe :run do
    it_behaves_like :run

    specify "raise if command returns a non-zero" do
      begin  @host.run "false"; rescue Gofer::Error => e
        expect(e).to be_kind_of Gofer::Error
        expect(e.host).to be_kind_of Gofer::Remote
        expect(e.message).to match(/failed with exit status/)
      end
    end
  end

  describe :read do
    it "reads the contents of a file" do
      with_tmp do
        expect(@host.read(create_tmpfile("hello", "hello\nworld")).strip).to \
          eq "hello\nworld"
      end
    end
  end

  describe :write do
    specify "files" do
      with_tmp do
        file = @tmpdir.join("hello")
        @host.write("world", file)
        expect(file.file?).to eq true
        expect(file.read.strip).to eq "world"
      end
    end
  end

  describe :upload do
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

  describe :download do
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
