require "rspec/helper"

describe Gofer::Cluster do

  before :all do
    @host1 = Gofer::Host.new("127.0.0.1", ENV["USER"], quiet: true)
    @host2 = Gofer::Host.new("127.0.0.2", ENV["USER"], quiet: true)
    [@host1, @host2].each do |v|
      (@cluster ||= Gofer::Cluster.new) << v
    end
  end

  specify "run commands async" do
    results = @cluster.run("bash -l -c \"ruby -e 'puts Time.now.to_i; sleep 1; puts Time.now.to_i'\"")
    res1 = results[@host1].stdout.lines.to_a
    res2 = results[@host2].stdout.lines.to_a
    expect(res1[0]).to eq res2[0]
    expect(res1[1]).to eq res2[1]
  end

  context do
    before(:all) { @cluster.max_concurrency = 1   }
    after (:all) { @cluster.max_concurrency = nil }

    specify "respect max_concurrency" do
      results = @cluster.run("bash -l -c \"ruby -e 'puts Time.now.to_i; sleep 1; puts Time.now.to_i'\"")
      res1 = results[@host1].stdout.lines.to_a
      res2 = results[@host2].stdout.lines.to_a

      expect(res1[0].to_i + 1).to eq res2[0].to_i
      expect(res1[1].to_i + 1).to eq res2[1].to_i
    end
  end

  it "should encapsulate errors in a Gofer::ClusterError container exception" do
    expect { @cluster.run("false") }.to raise_error(Gofer::ClusterError)

    begin; @cluster.run "false"
    rescue Gofer::ClusterError => e
      expect(e.errors.keys.length).to eq(2)
      expect(e.errors[@host1]).to be_a(Gofer::HostError)
      expect(e.errors[@host2]).to be_a(Gofer::HostError)
    end
  end

  def results_should_eq expected, &block
    results = block.call
    expect(results[@host1]).to eq expected
    expect(results[@host2]).to eq expected
  end

  describe :exist? do
    specify "return true if exists" do
      with_tmp do
        results_should_eq(true)  { @cluster.exist?(@tmpdir) }
      end
    end

    specify "return false if ! exist" do
      with_tmp do
        results_should_eq(false) { @cluster.exist?(@tmpdir + '/blargh') }
      end
    end
  end

  describe :directory? do
    specify "return true if directory" do
      with_tmp do
        results_should_eq(true) { @cluster.directory?(@tmpdir) }
      end
    end

    specify "return false if directory" do
      with_tmp do
        results_should_eq(false) { @cluster.directory?(create_tmpfile("hello")) }
      end
    end
  end

  describe :read do
    specify "read the contents" do
      with_tmp do
        results_should_eq("world") { @cluster.read(create_tmpfile("hello", "world")) }
      end
    end
  end

  describe :ls do
    it "lists the contents of a directory" do
      with_tmp do
        results_should_eq(["lstmp"]) do
          @cluster.ls(File.dirname(create_tmpfile("lstmp")))
        end
      end
    end
  end

  describe :upload do
    specify "upload the damn file" do
      with_tmp do
        meth0 = @cluster.hosts[0].method(:upload)
        meth1 = @cluster.hosts[1].method(:upload)

        client_file0 = create_tmpfile("hello0", "hello0")
        client_file1 = create_tmpfile("hello1", "hello1")
        server_file0 = @tmpdir.join("world0")
        server_file1 = @tmpdir.join("world1")

        allow(@cluster.hosts[0]).to receive(:upload) { |_, _| meth0.call(client_file0, server_file0) }
        allow(@cluster.hosts[1]).to receive(:upload) { |_, _| meth1.call(client_file1, server_file1) }
        @cluster.upload

        expect(server_file0.file?).to eq true
        expect(server_file1.file?).to eq true
        expect(server_file0.read.strip).to eq "hello0"
        expect(server_file1.read.strip).to eq "hello1"
      end
    end
  end

  describe :write do
    specify "write the damn file" do
      with_tmp do
        meth0 = @cluster.hosts[0].method(:write)
        meth1 = @cluster.hosts[1].method(:write)
        file0 = @tmpdir.join("hello0")
        file1 = @tmpdir.join("hello1")

        allow(@cluster.hosts[0]).to receive(:write) { |text, _| meth0.call(text, file0) }
        allow(@cluster.hosts[1]).to receive(:write) { |text, _| meth1.call(text, file1) }

        @cluster.write("world", nil)
        expect(file0.file?).to eq true
        expect(file1.file?).to eq true
        expect(file0.read ).to eq "world"
        expect(file1.read ).to eq "world"
      end
    end
  end

  describe :download do
    specify "should not be implemented" do
      expect { @cluster.download("whut") }.to raise_error(NoMethodError)
    end
  end
end
