require "gofer/helpers/ansi"

module Gofer
  module Helpers
    class Stdio
      KNOWN_OPTS = [ :ansi, :quiet_stdout, :quiet_stderr, :output_prefix, :stderr, :stdout ]

      def initialize(opts)
        @prefix_next_line = true
        @opts = opts

        @opts[:stdout] ||= $stdout
        @opts[:stderr] ||= $stderr

        unless (bad = @opts.keys - KNOWN_OPTS).empty?
          raise ArgumentError, "invalid opts on @opts #{bad}"
        end
      end

      { :stdout => :green, :stderr => :red }.each do |key, value|
        define_method key do |str, opts = {}|
          opts = normalize_opts(opts)

          unless opts[:"quiet_#{key}"]
            opts[key].write(wrap_ansi(value, wrap_output(str, opts[:output_prefix]), opts))
          end
        end
      end

      private
      def wrap_ansi(color, str, opts)
        ! opts[:ansi] ? str : Ansi.wrap(color, str)
      end

      private
      def wrap_output(str, output_prefix)
        return  str unless output_prefix

        if @prefix_next_line
          str = "#{output_prefix}: #{str}"
        end

        @prefix_next_line = str.end_with?("\n")
        str.gsub(/\n(.)/, "\n#{output_prefix}: \\1")
      end

      private
      def normalize_opts(opts)
        opts.merge_if!(
          @opts
        )
      end
    end
  end
end
