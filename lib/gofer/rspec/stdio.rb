module Gofer
  module Rspec
    class Stdio < Gofer::Helpers::Stdio
      def stdout(line, opts)
        opts = normalize_opts(opts)
        if opts.size > 0
          stringio.write(line)
        end
      end

      def stringio
        @stringio ||= StringIO.new
      end
    end
  end
end
