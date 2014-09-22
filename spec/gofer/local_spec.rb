require "rspec/helper"

describe Gofer::Local do
  before :all do
    @host = Gofer::Local.new(:quiet => true)
  end

  specify "#hostname == localhost" do
    expect(@host.hostname).to eq "localhost"
  end

  specify "#username == ENV['USER']" do
    expect(@host.username).to eq ENV["USER"]
  end

  describe :run do
    it_behaves_like :run
    specify "raise if command returns a non-zero" do
      expect { @host.run "false" }.to raise_error Gofer::HostError
      begin  @host.run "false"; rescue Gofer::HostError => e
        expect(e).to be_kind_of Gofer::HostError
        expect(e.host).to be_kind_of Gofer::Local
        expect(e.message).to match(/failed with exit status/)
      end
    end
  end
end
