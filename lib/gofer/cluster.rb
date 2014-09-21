require "thread"

module Gofer

  # ---------------------------------------------------------------------------
  # A collection of Gofer::Host instances that can run commands simultaneously
  #
  # Gofer::Cluster supports most of the methods of Gofer::Host. Commands
  # will be run simultaneously, with up to +max_concurrency+ commands running
  # at the same time. If +max_concurrency+ is unset all hosts in the cluster
  # will receive commands at the same time.
  #
  # Results from commands run are returned in a Hash, keyed by host.
  # ---------------------------------------------------------------------------

  class Cluster
    attr_accessor :max_concurrency
    attr_reader   :hosts

    # -------------------------------------------------------------------------
    # Create a new cluster of Gofer::Host connections.
    #
    # @param parties [Array] Gofer::Host or other Gofer::Cluster instances
    # @opt opts max_concurrency [String] Maximum number of commands to async.
    # -------------------------------------------------------------------------

    def initialize(parties=[], opts={})
      @hosts, @max_concurrency = [], opts.delete(:max_concurrency)
      parties.each do |i|
        self << i
      end
    end

    # -------------------------------------------------------------------------
    # Currency effective concurrency, either +max_concurrency+ or the number of
    # Gofer::Host instances we contain.
    # -------------------------------------------------------------------------

    def concurrency
      max_concurrency.nil? ? hosts.length : [max_concurrency, hosts.length].min
    end

    # -------------------------------------------------------------------------
    # Add a Gofer::Host or the hosts belonging to a Gofer::Cluster to this instance.
    # -------------------------------------------------------------------------

    def <<(other)
      case other
        when Host then @hosts << other
        when Cluster then other.hosts.each do |h|
          self << h
        end
      end
    end

    # -------------------------------------------------------------------------

    [:run, :exist?, :directory?, :ls, :upload, :read, :write].each do |k|
      define_method k do |*a|
        threaded(k, *a)
      end
    end

    # -------------------------------------------------------------------------
    # Spawn +concurrency+ worker threads, each of which pops work off the
    # +_in+ queue, and writes values to the +_out+ queue for syncronisation.
    # -------------------------------------------------------------------------

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

      length.times do
        _out.pop
      end

      # Give it to them because they need it nao.
      errors.size > 0 ? raise(Gofer::ClusterError.new(errors)) : results
    end

    # -------------------------------------------------------------------------

    def run_queue
      Queue.new.tap do |q|
        @hosts.each do |h|
          q << h
        end
      end
    end
  end
end
