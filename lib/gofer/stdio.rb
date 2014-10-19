require "gofer/ansi"

module Gofer
  class Stdio
    KNOWN_OPTS = [
      :ansi, :quiet_stdout,
      :quiet_stderr, :output_prefix,
      :stderr, :stdout
    ]

    def initialize(opts)
      @prefix_next_line = true
      @opts = opts

      @opts[:stdout] ||= $stdout; @opts[:stderr] ||= $stderr
      unless (bad = @opts.keys - KNOWN_OPTS).empty?
        raise ArgumentError, "invalid opts on @opts #{bad}"
      end
    end

    { :stdout => :green, :stderr => :red }.each do |k ,v|
      define_method k do |d, o = {}|
        unless (o = normalize_opts(o)) && o.send(:[], :"quiet_#{k}")
          o[k].write wrap_ansi(
            v, wrap_output(d, o[:output_prefix]), o
          )
        end
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
      opts.merge_if(
        @opts
      )
    end
  end
end
