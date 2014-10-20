require "gofer/deploy/extensions/string"
require "gofer/deploy/extensions/rake"
require "yaml"
require "gofer"

module Gofer
  class Deploy
    BASE_RSYNC_CMD  = "rsync -av --filter=':- .deploy.ignore' --filter=':- .gitignore'"
    BASE_DEBUG_LINE = "run %s from %s on %s"
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

    def initialize(opts = {})
      @opts = opts
    end

    def config
      @config ||= \
        parse_config
    end

    def run(cmd, opts = {})
      opts = normalize_opts(opts)
      cmd = attach_argv(cmd, opts[:argv])
      gofer = gofer_opts(opts)

      unless opts[:server].is_a?(Remote) || opts[:server].is_a?(Local)
        opts[:server] = config[:deploy_servers][opts[:server]]
      end

      output_debug(cmd, opts)
      ret = opts[:server].run(cmd, gofer)
      exit(ret.exit_status) if ! opts[:capture] && ret.exit_status != 0
    ret
    end

    def attach_argv(cmd, argv)
      argv = build_argv(argv) if argv.is_a?(Hash)
      return cmd if argv.nil? || argv.empty?

      out = cmd.rpl(:argv, argv)
      if out == cmd && out = out.split("\s")
        out.each_with_index do |k, i|
          next if k.nil? || k.empty?
          out[i] << " #{argv}"
          break
        end

        out = out.join(
          "\s"
        )
      end
    out
    end

    def build_argv(hash)
      return "" if hash.empty?
      hash.inject("") do |s, (k, v)|
        unless v == false
          s << (k.size == 1 ? " -#{k}" : " --#{k}")
          s << " #{v}" unless v.nil? || v == "" || v == true
        end

        s
      end.strip
    end

    private
    def output_debug(cmd, opts)
      if ! opts[:skip_debug] && config[:deploy_output_level] >= 2
        opts[:stderr].write BASE_DEBUG_LINE % [
          Ansi.yellow(cmd.chomp("\s")),
          Ansi.yellow(Rake.current_task || "none"),
          Ansi.yellow(opts[:server])
        ]

        output_env_debug(opts)
        opts[:stdout].write "\n"
      end
    end

    private
    def output_env_debug(opts)
      if opts[:env] && opts[:env].size > 0
        env = opts[:env].dup.delete_if { |k, v| v.nil? || v.empty? }
        env = env.map { |k, v| "#{k}=#{v}" }.join("\s")
        opts[:stderr].write " with env #{Ansi.yellow(env)}"
      end
    end

    private
    def gofer_opts(opts)
      opts[:gofer].merge({
        :stderr => opts[:stderr],
        :env => opts[:env],
        :stdout => opts[:stdout]
      })
    end

    private
    def base_normalized_opts
      @base_normalized_opts ||= \
        { :env => config[:deploy_env] }.elegant_merge(@opts)
    end

    private
    def normalize_opts(opts)
      opts = base_normalized_opts.elegant_merge(opts)
      opts.merge_if({
        :server  => config[:default_server],
        :stdout  => $stdout,
        :stderr  => $stderr,
        :capture => false  ,

        :argv => {

        },

        :env => {
          :PWD => (opts[:server] == :localhost ? nil : \
            config[config[:default_pwd]])
        },

        :gofer => {
          :capture_exit_status => true,
          :quiet_stdout => config[:deploy_output_level]  < 1,
          :quiet_stderr => config[:deploy_output_level] == 0,
          :ansi => true
        }
      })
    end

    private
    def parse_config
      base_config = normalize_deploy_servers(DEFAULTS.merge(read_config))
      base_config.inject({}) do |h, (k, v)|
        h.update(normalize_config_value(k, v, base_config["app"]))
      end. \
      symbolize_keys
    end

    private
    def normalize_deploy_servers(out)
      localhost = { "localhost" => Gofer::Local.new }
      out["deploy_servers"] ||= {}
      out["deploy_servers"] = out["deploy_servers"].inject(localhost) do |h, (k, v)|
        h.update(k => Gofer::Remote.new(v, k))
      end
    out
    end

    private
    def normalize_config_value(k, v, app_name)
      v = case true
        when k !~ /\Adefault_/ && v.is_a?(String) then v.rpl(:app, app_name)
        when k =~ /\Adefault_/ && v.is_a?(String)
          v.to_s.rpl(:app, app_name).to_sym
      else
        v
      end

      return {
        k => v
      }
    end

    private
    def read_config
      # Rails >= 4.2 supports +#config_for+ to getting a configuration file.
      if ! ENV["DEPLOY_CONFIG"] && (defined?(Rails) && Rails.application.respond_to?(:config_for))
        then Rails.application.config_for(:deploy)["development"]
        else YAML.load_file(ENV["DEPLOY_CONFIG"] || "deploy.yml")
      end
    end

    class << self
      def globalize_ssh(opts = {})
        Object.send(:define_method, :ssh) { @ssh ||= Gofer::Deploy.new(opts) }
      end
    end
  end
end
