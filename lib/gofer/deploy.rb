require "gofer/deploy/extensions/string"
require "gofer/deploy/extensions/rake"
require "gofer/deploy/configuration"
require "gofer/deploy/debug"
require "yaml"
require "gofer"

module Gofer
  class Deploy
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

    def initialize(opts = {})
      @opts = opts
    end

    def config
      @config ||= \
        Configuration.new.read
    end

    def base_normalized_opts
      @base_normalized_opts ||= \
        { :env => config[:deploy_env] }.elegant_merge(@opts)
    end

    def run(cmd, opts = {})
      opts, cmd = normalize_opts_and_cmd(opts, cmd)
      res = opts[:server].run(cmd, opts[:gofer])
      Debug.new(res, cmd, opts, config).printit.exit_ondemand!
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

        out = out.join("\s")
      end
    out
    end

    def build_argv(hash)
      return "" if hash.nil? || hash.empty?
      hash.delete_if { |k, v| v == false }
      out = hash.inject("") do |str, (k, v)|
        str << (k.size == 1 ? " -#{k}" : " --#{k}")
        unless v.nil? || v.empty? || v == true
          str << " #{Shellwords.shellescape(v)}"
        end
      str
      end. \
      strip
    end

    private
    def normalize_opts_and_cmd(opts, cmd)
      [
        (opts = normalize_opts(opts)),
        attach_argv(cmd, opts[:argv])
      ]
    end

    private
    def set_gofer(opts)
      opts[:gofer] = opts[:gofer].merge_if({
        :stderr => opts[:stderr],
        :env => opts[:env],
        :stdout => opts[:stdout]
      })
    opts
    end

    private
    def set_server(opts)
      unless opts[:server].is_a?(Remote) || opts[:server].is_a?(Local)
        opts[:server] = config[:deploy_servers][opts[:server]]
      end
    opts
    end

    private
    def normalize_opts(opts)
      opts = base_normalized_opts.elegant_merge(opts)
      set_gofer(set_server(opts.merge_if({
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
      })))
    end

    class << self
      def globalize_ssh(opts = {})
        Object.send(:define_method, :ssh) { @ssh ||= Gofer::Deploy.new(opts) }
      end
    end
  end
end
