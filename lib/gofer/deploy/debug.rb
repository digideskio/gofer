module Gofer
  class Deploy
    class Debug
      attr_reader :opts, :config, :cmd, :debug
      BASE_DEBUG_LINE = "run %s from %s on %s"

      def initialize(cmd, opts, config)
        @opts = opts
        @config = config
        @cmd = cmd
      end

      def inspect
        %Q{<#{self.class} #{@cmd}>}
      end

      def response
        @debug.response
      end

      def debug=(value)
        @debug ? (return) : @debug = value
      end

      def exit_if_asked
        unless @opts[:capture_exit_status] || response.exit_status == 0
          exit(response.exit_status)
        end
      self
      end

      def print
        if ! @opts[:skip_debug_output] && @config[:deploy_output_level] >= 2
          @opts[:stderr].write BASE_DEBUG_LINE % [*Gofer::Helpers::Ansi.mcolor_single(
            cmd.chomp("\s"),
            Rake.current_task || "none",
            @opts[:server],
            :yellow
          )]

          print_env
          @opts[:stdout].write "\n"
        end
      self
      end

      private
      def print_env
        if @opts[:env] && @opts[:env].size > 0
          env = @opts[:env].dup.delete_if { |k, v| v.nil? || v.empty? }
          env = env.map { |k, v| "#{k}=#{v}" }.join("\s")
          @opts[:stderr].write " with env #{Gofer::Helpers::Ansi.wrap(:yellow, env)}"
        end
      end
    end
  end
end
