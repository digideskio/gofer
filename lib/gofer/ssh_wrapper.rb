require 'net/ssh'
require 'net/scp'

module Gofer
  class SshWrapper
    attr_reader :last_output, :last_exit_status

    def initialize(*args)
      @net_ssh_args, @at_start_of_line = args, true
    end

    def run(command, opts = {})
      ssh_execute(ssh, command, opts)
    end

    def read_file(path)
      scp.download!(
        path
      )
    end

    [:download, :upload].each do |k|
      define_method k do |f, t, o = {}|
        scp.send("#{k}!", f, t, o)
      end
    end

    private
    def ssh
      @ssh ||= Net::SSH.start(*@net_ssh_args)
    end

    private
    def scp
      @scp ||= Net::SCP.new(ssh)
    end

    def ssh_execute(ssh, command, opts={})
      stdout, stderr, output, exit_code = '', '', '', 0
      ssh.open_channel do |c|
        c.exec(command) do |_, s|
          raise "SSH Channnel: Couldn't execute command #{command}" unless s

          c.on_data do |_, d|
            stdout += d and output += d
            unless opts[:quiet]
              $stdout.print wrap_output(d, opts[:output_prefix])
            end
          end

          c.on_extended_data do |_, t, d|
            next unless t == 1
            stderr += d and output += d
            unless opts[:quiet_stderr]
              $stderr.print wrap_output(d, opts[:output_prefix])
            end
          end

          c.on_request("exit-status") do |_, d|
            exit_code = d.read_long
            c.close
          end

          if opts[:stdin]
            c.send_data(opts[:stdin])
            c.eof!
          end
        end
      end

      ssh.loop
      Gofer::Response.new(stdout, stderr, output, exit_code)
    end

    private
    def wrap_output(output, prefix)
      return output unless prefix
      output = "#{prefix}: " + output if @at_start_of_line
      @at_start_of_line = output.end_with?("\n")
      output.gsub(/\n(.)/, "\n#{prefix}: \\1")
    end
  end
end
