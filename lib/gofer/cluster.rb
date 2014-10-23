require "gofer/cluster/error"
require "gofer/remote"
require "thread"

module Gofer
  class Cluster
    attr_accessor :max_concurrency
    attr_reader :hosts

    def initialize(parties = [], opts = {})
      @max_concurrency = opts[:max_concurrency].to_s.to_i
      @mutex = Mutex.new
      @hosts = []

      parties.each do |i|
        self << i
      end
    end

    def concurrency
      if ! @max_concurrency || @max_concurrency == 0
        hosts.length
      else
        min = [@max_concurrency, @hosts.length].min
        min > 0 ? min : hosts.length
      end
    end

    def <<(other)
      case true
      when other.is_a?(Remote)
        @hosts << other

      when other.is_?(Cluster)
        other.hosts.each do |host|
          @hosts << host
        end
      end
    end

    [:run, :upload, :read, :write].each do |key|
      define_method key do |*args|
        threaded(key, *args)
      end
    end

    private
    def lock
      @mutex.synchronize do
        yield
      end
    end

    private
    def host_queue
      out = Queue.new

      @hosts.each do |v|
        out << v
      end

      out
    end

    private
    def threaded(meth, *args)
      results = {}
      errors  = {}

      with_threadpool do |host|
        begin
          result = host.send(meth, *args)

          lock do
            results[host] = result
          end
        rescue Gofer::Error => error
          lock do
            errors[host] = error
          end
        end
      end

      errors.size == 0 ? results : raise(Gofer::Cluster::Error.new(errors))
    end

    private
    def with_threadpool(&block)
      queue = host_queue
      threads = []

      concurrency.times do |v|
        threads << Thread.new do
          until queue.empty? || ! (host = queue.pop(true) rescue nil)
            block.call(host)
          end
        end
      end

      threads.map(&:join)
    end
  end
end
