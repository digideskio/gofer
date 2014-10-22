module Gofer
  class Deploy
    class Debug
      BASE_DEBUG_LINE = "run %s from %s on %s"
      attr_reader :cmd, :opts, :response

      def initialize(response, cmd, opts, config)
        @opts = opts
        @response = response
        @config = config
        @cmd = cmd
      end

      def exit_ondemand!
        unless @opts[:capture] || @response.exit_status == 0
          exit(@response.exit_status)
        end
      self
      end

      def printit
        if ! @opts[:skip_debug] && @config[:deploy_output_level] >= 2
          @opts[:stderr].write BASE_DEBUG_LINE % [*Ansi.mcolor_single(
            cmd.chomp("\s"),
            Rake.current_task || "none",
            @opts[:server],
            :yellow
          )]

          printit_env
          @opts[:stdout].write "\n"
        end
      self
      end

      private
      def printit_env
        if @opts[:env] && @opts[:env].size > 0
          env = @opts[:env].dup.delete_if { |k, v| v.nil? || v.empty? }
          env = env.map { |k, v| "#{k}=#{v}" }.join("\s")
          @opts[:stderr].write " with env #{Ansi.wrap(:yellow, env)}"
        end
      end
    end
  end
end
