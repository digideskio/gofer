module Gofer
  class Stdio
    KNOWN_OPTIONS = [
      :stderr, :stdout,
      :quiet_stderr, :output_prefix,
      :quiet_stdout
    ]

    def initialize(opts)
      @opts = opts
      @prefix_next_line = true
      @opts[:stdout] ||= $stdout
      @opts[:stderr] ||= $stderr
    end

    # Print each line to stdout after wrapping it using +#wrap_output+ to wrap
    # it with the output prefix the user supplies.

    def stdout(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet_stdout]
        opts[:stdout].write wrap_output(
          data, opts[:output_prefix]
        )
      end
    end

    # Print each line to stderr after wrapping it using +#wrap_output+ to wrap
    # it with the output prefix the user supplies.

    def stderr(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet_stderr]
        opts[:stderr].write wrap_output(
          data, opts[:output_prefix]
        )
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
      KNOWN_OPTIONS.each do |k|
        opts[k] = @opts[k] unless opts.has_key?(k)
      end
    opts
    end
  end
end
