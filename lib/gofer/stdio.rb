module Gofer
  class Stdio

    def initialize(opts)
      @quiet_stderr = opts.delete(:quiet_stderr)
      @output_prefix = opts.delete(:output_prefix)
      @quiet = opts.delete(:quiet)
    end

    # Print each line to stdout after wrapping it using +#wrap_output+ to wrap
    # it with the output prefix the user supplies.

    def stdout(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet]
        $stdout.write wrap_output(data, opts[:output_prefix])
      end
    end

    # Print each line to stderr after wrapping it using +#wrap_output+ to wrap
    # it with the output prefix the user supplies.

    def stderr(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet_stderr]
        $stderr.write wrap_output(data, opts[:output_prefix])
      end
    end

    # Wrap the line with with the +@output_prefix+ the user supplies.

    private
    def wrap_output(data, output_prefix)
      unless output_prefix
        return data
      end

      @at_start_of_line = data.end_with?("\n")
      data = "#{output_prefix}: " + data if @at_start_of_line
      data.gsub(/\n(.)/, "\n#{output_prefix}: \\1")
    end

    # Normalize the options so they are consistent and merged with opts that
    # are coming in via +#stderr+ and +#stdout+.

    private
    def normalize_opts(opt)
      opt[:quiet_stderr] = @quiet_stderr unless opt.has_key?(:quiet_stderr)
      opt[:output_prefix] = @output_prefix unless opt.has_key?(:output_prefix)
      opt[:quiet] = @quiet unless opt.has_key?(:quiet)
    opt
    end
  end
end
