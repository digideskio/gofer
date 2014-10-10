shared_examples_for :run do
  describe :run do
    describe "with stdout and stderr responses" do
      before :all do
        @response = @host.run("echo stdout; echo stderr 1>&2", {
          :quiet_stderr => true, :quiet => true
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
      specify "prefix first line of stdout and stderr" do
        out1, out2 = StringIO.new, StringIO.new
        @host.run "echo stdout; echo stdout2; echo stderr 1>&2; echo stderr2 1>&2", {
          :quiet => false,
          :quiet_stderr => false,
          :output_prefix => "derp",
          :stdout => out1,
          :stderr => out2
        }

        expect(out1.string.strip).to eq "derp: stdout\nderp: stdout2"
        expect(out2.string.strip).to eq "derp: stderr\nderp: stderr2"
      end

      specify "don't prefix continued output on new lines" do
        out = StringIO.new
        @host.run "echo -n foo; echo bar; echo baz; ", {
          :quiet => false, :output_prefix => "derp", :stdout => out
        }

        expect(out.string.strip).to eq "derp: foobar\nderp: baz"
      end
    end

    specify "process stdin when stdin is set" do
      out = StringIO.new
      @host.run "sed 's/foo/baz/'", :stdin => "foobar", :quiet => false, :stdout => out
      expect(out.string.strip).to eq "bazbar"
    end

    specify "capture a non-zero exit status if told" do
      response = @host.run("false", :capture_exit_status => true)
      expect(response.exit_status).to eq 1
    end
  end
end
