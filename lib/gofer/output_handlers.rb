module Gofer
  module OutputHandlers
    private
    def stdout(data, opts)
      unless opts[:quiet]
        $stdout.print wrap_output(data, opts[:output_prefix])
      end
    end

    private
    def stderr(data, opts)
      unless opts[:quiet_stderr]
        $stderr.print wrap_output(data, opts[:output_prefix])
      end
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
