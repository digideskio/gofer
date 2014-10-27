require "gofer/extensions/string"
require "gofer/extensions/rake"

require "gofer/deploy/helpers"
require "gofer/deploy/configuration"
require "gofer/deploy/debug"
require "gofer/remote"
require "gofer/local"
require "yaml"

class Gofer::Deploy
  include Helpers

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
    @config ||= Configuration.new.read
  end

  def base_normalized_opts
    @base_normalized_opts ||= { :env => config[:deploy_env] }.elegant_merge!(@opts)
  end

  def run(cmd, opts = {})
    opts = normalize_opts(opts)
    cmd = attach_argv(cmd, opts[:argv]) if opts[:argv]
    debug = Debug.new(cmd, opts, config)

    debug.print
    debug.debug = opts[:server].run(cmd, opts[:gofer])
    debug.exit_if_asked
  end

  def attach_argv(cmd, argv)
    argv = build_argv(argv) if argv.is_a?(Hash)
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

    hash.delete_if { |key, value| value == false }.stringize.inject("") do |str, (key, value)|
      key = key.size == 1 ? " -#{key}" : " --#{key}"

      unless value.nil? || value.empty? || value == true
        value = Shellwords.shellescape(value)
      end

      "#{str} #{key} #{value} "
    end. \
    strip
  end

  private
  def set_gofer(opts)
    opts[:gofer].merge_if!({
      :stderr => opts[:stderr],
      :env => opts[:env],
      :stdout => opts[:stdout]
    })

    opts
  end

  def get_server(server = nil)
    server ||= config[:default_server]
    server.is_a?(Gofer::Remote) || server.is_a?(Gofer::Local) ? server : config[:deploy_servers][server]
  end

  private
  def set_server(opts)
    opts[:server] = get_server(opts[:server])
    opts
  end

  private
  def set_env_pwd(opts)
    dpwd = config[config[:default_pwd]]
    unless opts[:env][:PWD] || opts[:server] == :localhost || dpwd.nil? || dpwd.empty?
      opts[:env][:PWD] = dpwd
    end

    opts
  end

  private
  def normalize_opts(opts)
    opts = base_normalized_opts.dup.elegant_merge!(opts)
    set_env_pwd(set_gofer(set_server(opts.merge_if!({
      :server  => config[:default_server],
      :stdout  => $stdout,
      :stderr  => $stderr,
      :capture => false  ,

      :env => {

      },

      :gofer => {
        :capture_exit_status => true,
        :quiet_stdout => config[:deploy_output_level]  < 1,
        :quiet_stderr => config[:deploy_output_level] == 0,
        :ansi => true
      }
    }))))
  end

  class << self
    def globalize_ssh(opts = {})
      Object.send(:define_method, :ssh) { @ssh ||= Gofer::Deploy.new(opts) }
    end
  end
end
