require "gofer/ansi"

module Gofer
  class Stdio
    KNOWN_OPTIONS = [
      :ansi, :quiet_stdout,
      :quiet_stderr, :output_prefix,
      :stderr, :stdout
    ]

    def initialize(opts)
      @opts = opts
      @prefix_next_line = true
      @opts[:stdout] ||= $stdout
      @opts[:stderr] ||= $stderr
    end

    def stdout(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet_stdout]
        opts[:stdout].write wrap_ansi(
          :green, wrap_output(data, opts[:output_prefix]), opts
        )
      end
    end

    def stderr(data, opts = {})
      unless (opts = normalize_opts(opts)) && opts[:quiet_stderr]
        opts[:stderr].write wrap_ansi(
          :red, wrap_output(data, opts[:output_prefix]), opts
        )
      end
    end

    private
    def wrap_ansi(color, str, opts)
      unless ! opts[:ansi]
        return Ansi.send(color, str)
      end
    str
    end

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

    private
    def normalize_opts(opts)
      KNOWN_OPTIONS.each do |k|
        opts[k] = @opts[k] unless opts.has_key?(k)
      end
    opts
    end
  end
end
