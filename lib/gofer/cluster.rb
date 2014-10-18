require "gofer/cluster_error"
require "thread"

module Gofer
  class Cluster
    attr_accessor :max_concurrency
    attr_reader :hosts

    def initialize(parties = [], opts = {})
      @max_concurrency = opts[:max_concurrency].to_s.to_i
      parties.each do |i|
        self << i
      end
    end

    def concurrency
      if ! @max_concurrency || @max_concurrency == 0
        hosts.length
      else
        r = [@max_concurrency, @hosts.length].min
        r > 0 ? r : hosts.length
      end
    end

    def <<(other)
      @hosts ||= []
      case other
        when Host then @hosts << other
        when Cluster then other.hosts.each do |h|
          self << h
        end
      end
    end

    [:run, :upload, :read, :write].each do |k|
      define_method k do |*a|
        threaded(k, *a)
      end
    end

    def lock
      (@mutex ||= Mutex.new).synchronize do
        yield
      end
    end

    def host_queue
      out = Queue.new and @hosts.each do |v|
        out << v
      end
    out
    end

    private
    def threaded(meth, *args)
      queue, threads, results, errors = host_queue, [], {}, {}
      concurrency.times do |v|
        threads << Thread.new do
          until queue.empty? || ! (host = queue.pop(true) rescue nil)
            begin
              result = host.send(meth, *args)
              lock { results[host] = result }
            rescue Gofer::Error => error
              lock do
                errors[host] = error
              end
            end
          end
        end
      end

      threads.map(&:join)
      errors.size > 0 ? raise(Gofer::ClusterError.new(errors)) : results
    end
  end
end
