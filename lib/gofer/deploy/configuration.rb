module Gofer
  class Deploy
    class Configuration
      extend Forwardable

      BASE_RSYNC_CMD  = "rsync -av --filter=':- .deploy.ignore' --filter=':- .gitignore'"
      DEFAULTS = {
        :deploy_output_level => 2,
        :deploy_env => {},
        :cmd => {
          :rsync => {
            :no_del => BASE_RSYNC_CMD,
               :del => BASE_RSYNC_CMD + " --delete --delete-excluded"
          }
        }
      }.freeze

      def_delegator :@config, :[]
      def_delegator :@config, :[]=
      def_delegator :@config, :each
      def_delegator :@config, :lazy
      def_delegator :@config, :inject
      def_delegator :@config, :has_key?
      def_delegator :@config, :each_with_index
      def_delegator :@config, :elegant_merge
      def_delegator :@config, :each_pair
      def_delegator :@config, :merge_if
      def_delegator :@config, :to_enum
      def_delegator :@config, :merge
      def_delegator :@config, :keys
      def_delegator :@config, :to_h
      def_delegator :@config, :to_a

      def read
        @config = normalize_deploy_servers(DEFAULTS.merge(read_config))
        @config = @config.inject({}) do |h, (k, v)|
          h.update(normalize_config_value(k, v, @config["app"]))
        end

        # Chainit.
        return self
      end

      private
      def normalize_deploy_servers(config)
        localhost = { :localhost => Gofer::Local.new }
        config["deploy_servers"] ||= {}
        config["deploy_servers"] = config["deploy_servers"].inject(localhost) do |hash, (key, value)|
          hash[key.to_sym] = Gofer::Remote.new(value, key)
          hash
        end

        config
      end

      private
      def normalize_config_value(k, v, app)
        v = case true
          when k !~ /\Adefault_/ && v.is_a?(String) then v.rpl(:app, app)
          when k =~ /\Adefault_/ && v.is_a?(String)
            v.to_s.rpl(:app, app).to_sym
        else
          v
        end

        return {
          (k.is_a?(String) ? k.to_sym : k) => v
        }
      end

      private
      def read_config
        if ENV["DEPLOY_CONFIG"] || ! defined?(Rails)
          out = YAML.load_file(ENV["DEPLOY_CONFIG"] || "deploy.yml")
          if out.size == 1 && out.has_key?("development")
            out = out["development"]
          end
        out
        else
          Rails.application.config_for(:deploy)["development"]
        end
      end
    end
  end
end
