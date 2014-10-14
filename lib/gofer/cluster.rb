require "gofer/cluster_error"
require "thread"

module Gofer
  class Cluster
    attr_accessor :max_concurrency
    attr_reader :hosts

    def initialize(parties = [], opts = {})
      @max_concurrency = opts.delete(:max_concurrency).to_s.to_i
      parties.each do |i|
        self << i
      end
    end

    # Currency effective concurrency, either +max_concurrency+ or the number of
    # Gofer::Host instances we contain.

    def concurrency
      if ! @max_concurrency || @max_concurrency == 0
        then hosts.length
        else (r = [@max_concurrency, @hosts.length].min) > 0 ? r : hosts.length
      end
    end

    # Add a Gofer::Host or the hosts belonging to a Gofer::Cluster to this
    # instance so that you can have hosts that are not in this and hosts that
    # are on this.  The choice is in your hands.

    def <<(other)
      @hosts ||= []
      case other
        when Host then @hosts << other
        when Cluster then other.hosts.each do |h|
          self << h
        end
      end
    end

    #

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

    # Spawn +concurrency+ worker threads, each of which pops work off the
    # +_in+ queue, and writes values to the +_out+ queue for syncronization.
    # And at the end go ahead and return an error or results.

    private
    def threaded(meth, *args)
      results, errors, threads = {}, {}, []
      @hosts.each_slice(concurrency).each do |v|
        threads = [ ]
        v.each do |h|
          threads << Thread.new do
            begin
              Timeout.timeout(h.timeout)  do
                result = h.send(meth, *args)

                lock do
                  results[h] = result
                end
              end
            rescue Timeout::Error, Exception => error
              lock do
                errors[h] = error
              end
            end
          end
        end

        # Run them.
        threads.map(&:join)
      end

      # And now you get your results.
      errors.size > 0 ? raise(Gofer::ClusterError.new(errors)) : results
    end
  end
end
