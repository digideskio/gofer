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

      specify "call procs on opts for stdout" do stdout = proc { }
        expect(stdout).to receive(:call)
        @host.run("echo stdout", :stdout => stdout)
      end

      specify "call procs on opts for stderr" do stderr = proc { }
        expect(stderr).to receive(:call)
        @host.run("echo stderr 1>&2", :stderr => stderr)
      end
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

    specify "capture a non-zero exit status if told" do
      response = @host.run("false", :capture_exit_status => true)
      expect(response.exit_status).to eq 1
    end
  end
end
