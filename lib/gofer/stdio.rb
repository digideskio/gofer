module Gofer
  class Stdio

    def initialize(opts)
      @stderr = opts.delete(:stderr)
      @quiet_stderr = opts.delete(:quiet_stderr)
      @output_prefix = opts.delete(:output_prefix)
      @stdout = opts.delete(:stdout)
      @quiet = opts.delete(:quiet)
      @prefix_next_line = true
    end

    # Print each line to stdout after wrapping it using +#wrap_output+ to wrap
    # it with the output prefix the user supplies.

    def stdout(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet]
        opts[:stdout].write wrap_output(data, opts[:output_prefix])
      end
    end

    # Print each line to stderr after wrapping it using +#wrap_output+ to wrap
    # it with the output prefix the user supplies.

    def stderr(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet_stderr]
        opts[:stderr].write wrap_output(data, opts[:output_prefix])
      end
    end

    # Wrap the line with with the +@output_prefix+ the user supplies.

    private
    def wrap_output(out, output_prefix)
      unless output_prefix
        return out
      end

      out = "#{output_prefix}: " + out \
        if @prefix_next_line

      @prefix_next_line = out.end_with?("\n")
      out.gsub(/\n(.)/, "\n#{output_prefix}: \\1")
    end

    # Normalize the options so they are consistent and merged with opts that
    # are coming in via +#stderr+ and +#stdout+.

    private
    def normalize_opts(opts)
      opts[:stderr] = @stderr unless opts.has_key?(:stderr)
      opts[:quiet_stderr] = @quiet_stderr unless opts.has_key?(:quiet_stderr)
      opts[:output_prefix] = @output_prefix unless opts.has_key?(:output_prefix)
      opts[:quiet] = @quiet unless opts.has_key?(:quiet)
      opts[:stdout] = @stdout unless opts.has_key?(:stdout)
    opts
    end
  end
end
