require "rspec/helper"

describe Gofer::Local do
  before :all do
    @host = Gofer::Local.new(:quiet_stdout => true)
  end

  specify("#hostname == localhost")   { expect(@host.hostname).to eq "localhost" }
  specify("#to_s == user@host") { expect(@host.to_s).to eq "#{ENV["USER"]}@localhost" }
  specify("#username == ENV['USER']") { expect(@host.username).to eq ENV["USER"] }

  specify "#inspect" do
    expect(@host.inspect).to eq %Q{<Gofer::Local "#{ENV["USER"]}@localhost">}
  end

  it "accepts a custom stdio" do
    host = Gofer::Local.new({
      :stdio => Gofer::Rspec::Stdio
    })

    host.run("echo hello")
    expect(host.send(:stdio)).to be_kind_of Gofer::Rspec::Stdio
    expect(host.send(:stdio).stringio.string.strip).to eq "hello"
  end

  describe :run do
    it_behaves_like :run

    specify "raise if command returns a non-zero" do
      expect { @host.run "false" }.to raise_error Gofer::Error
      begin  @host.run "false"; rescue Gofer::Error => e
        expect(e).to be_kind_of Gofer::Error
        expect(e.host).to be_kind_of Gofer::Local
        expect(e.message).to match(/command[^\b]+exited with \d/)
      end
    end
  end
end
