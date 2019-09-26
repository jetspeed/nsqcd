require 'nsqcd/queue'
require 'nsqcd/support/utils'

module Nsqcd
  module Worker
    attr_reader :topic, :id, :opts

    include Concerns::Logging
    include Nsqcd::ErrorReporter

    def initialize(topic = nil, pool = nil, opts = {})
      opts = opts.merge(self.class.queue_opts || {})
      opts = Nsqcd::CONFIG.merge(opts)

      @pool = pool || Concurrent::FixedThreadPool.new(opts[:threads] || Nsqcd::Configuration::DEFAULTS[:threads])
      @call_with_params = respond_to?(:work_with_params)
      @content_type = opts[:content_type]

      @opts = opts
      @id = Utils.make_worker_id(queue_name)
    end

    def reject!; :reject; end
    def requeue!; :requeue; end

    def run
      worker_trace "New worker: #{self.class}."
      consumer = Nsq::Consumer.new(opts)
      do_work(consumer.pop)
      worker_trace "New worker: I'm alive."
    end

    def publish(msg, opts)
      topic = opts.delete(:topic)
      producer = Nsq::Producer.new(opts[:nsqlookupd], topic)
      producer.write(msg)
    end


    def do_work(msg)
      worker_trace "Working off: #{msg.inspect}"

      @pool.post do
        process_work(msg)
      end
    end

    def process_work(msg)
      res = nil
      begin
        metrics.increment("work.#{self.class.name}.started")
        metrics.timing("work.#{self.class.name}.time") do
          work(deserialized_msg)
        end
      rescue StandardError, ScriptError => ex
        res = :error
        worker_error(ex, log_msg: log_msg(msg), class: self.class.name, message: msg)
      end
      metrics.increment("work.#{self.class.name}.handled.#{res || 'noop'}")
      metrics.increment("work.#{self.class.name}.ended")
    end

    def stop
      worker_trace "Stopping worker: unsubscribing."
      @queue.unsubscribe
      worker_trace "Stopping worker: shutting down thread pool."
      @pool.shutdown
      @pool.wait_for_termination
      worker_trace "Stopping worker: I'm gone."
    end
    # Construct a log message with some standard prefix for this worker
    #
    def log_msg(msg)
      "[#{@id}][#{Thread.current}][#{@queue.name}][#{@queue.opts}] #{msg}"
    end

    def worker_trace(msg)
      logger.debug(log_msg(msg))
    end

    Classes = []

    def self.included(base)
      base.extend ClassMethods
      Classes << base if base.is_a? Class
    end

    module ClassMethods
      attr_reader :topic, :channel, :opts

      def from(t, opts={})
        @topic = t.to_s
        @opts = opts
      end

      def enqueue(msg, opts={})
        opts[:to_queue] ||= @topic
        publisher.publish(msg, opts)
      end

      private

      def publisher
        @publisher ||= Nsqcd::Publisher.new(queue_opts)
      end
    end
  end
end
