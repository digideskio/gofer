require "gofer/deploy"

describe Gofer::Deploy do
  before :all do
    ENV["DEPLOY_CONFIG"] = File.expand_path("../../support/deploy.yml", __FILE__)
    @deploy = Gofer::Deploy.new(:server => :mock, :skip_debug => true)
    @deploy.config[:deploy_servers][:mock] = MockRemote.new
  end

  specify "output useful debug information" do
    old_opl = @deploy.config[:deploy_output_level]
    @deploy.config[:deploy_output_level] = 10
    out1, out2 = StringIO.new, StringIO.new
    @deploy.run("echo hello", :stdout => out1, :stderr => out2, :skip_debug => false)
    @deploy.config[:deploy_output_level] = old_opl

    # Run this last because it leaves early and will kill the output_level reset.
    expect(Gofer::Helpers::Ansi.strip(out2.string)).to match "run echo hello from none on mock@mock with env"
  end

  context "argv" do
    specify "attach them where %{argv} is specificed" do
      ret = @deploy.run("hello world %{argv}", :argv => { :great => :day })
      expect(ret.cmd).to eq "hello world --great day"
    end

    specify "attach argv early if no %{argv}" do
      ret = @deploy.run("hello world", :argv => { :great => :day })
      expect(ret.cmd).to eq "hello --great day world"
    end
  end

  it "allows you to globalize deploy as Object#ssh" do
    Gofer::Deploy.globalize_ssh
    expect(defined?(ssh)).to eq "method"
    expect(ssh).to be_kind_of Gofer::Deploy
  end

  specify "run a command on Gofer::{Local,Remote}" do
    with_tmp do |t|
      o = t.create_tmpfile("foobar", "foobar")
      out1, out2 = StringIO.new, StringIO.new
      ret = @deploy.run("cat #{o}", {
        :stdout => out1,
        :capture => true,
        :server => :localhost,
        :stderr => out2,
        :pry => true,
      })

      expect(ret.response).to eq "foobar"
    end
  end

  context "config" do
    it "accepts ENV[DEPLOY_CONFIG]" do
      expect(@deploy.config.has_key?(:deploy_servers)).to eq true
      expect(@deploy.config[:deploy_servers].keys - [:mock]).to eq [:localhost]
    end

    it "converts %{app} into the key" do
      expect(@deploy.config[:deploy_folder]).to eq "/var/lib/app/www"
    end
  end
end
