require "gofer/cluster_error"
require "thread"

module Gofer
  class Cluster
    attr_accessor :max_concurrency
    attr_reader :hosts

    def initialize(parties = [], opts = {})
      @hosts, @max_concurrency = [], opts.delete(:max_concurrency)
      parties.each do |i|
        self << i
      end
    end

    # Currency effective concurrency, either +max_concurrency+ or the number of
    # Gofer::Host instances we contain.

    def concurrency
      if ! @max_concurrency
        then hosts.length
        else [ @max_concurrency, @hosts.length ].min
      end
    end

    # Add a Gofer::Host or the hosts belonging to a Gofer::Cluster to this
    # instance so that you can have hosts that are not in this and hosts that
    # are on this.  The choice is in your hands.

    def <<(other)
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

    # Spawn +concurrency+ worker threads, each of which pops work off the
    # +_in+ queue, and writes values to the +_out+ queue for syncronization.
    # And at the end go ahead and return an error or results.

    private
    def threaded(meth, *args)
      results_semaphore, errors_semaphore = Mutex.new, Mutex.new
      _in, _out = run_queue, Queue.new
      results, errors = {}, {}
      length = _in.length

      concurrency.times do
        Thread.new do
          loop do
            host = _in.pop(false) rescue Thread.exit

            begin
              result =  host.send(meth, *args)
              results_semaphore.synchronize do
                results[host] = result
              end
            rescue Exception => e
              errors_semaphore.synchronize do
                errors[host] = e
              end
            end

            _out << true
          end
        end
      end

      length.times { _out.pop }
      errors.size > 0 ? raise(Gofer::ClusterError.new(errors)) : results
    end

    def run_queue
      Queue.new.tap do |q|
        @hosts.each do |h|
          q << h
        end
      end
    end
  end
end
