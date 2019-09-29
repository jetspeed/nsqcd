require 'nsqcd/support/utils'
require 'nsq'

module Nsqcd
  module Worker
    attr_reader :topic, :channel, :id, :opts

    include Concerns::Logging
    include Nsqcd::ErrorReporter

    def initialize(pool = nil, opts = {})
      opts = opts.merge(self.class.opts || {})
      opts = Nsqcd::CONFIG.merge(opts)

      @pool = pool || Concurrent::FixedThreadPool.new(opts[:threads] || Nsqcd::Configuration::DEFAULTS[:threads])
      @call_with_params = respond_to?(:work_with_params)
      @content_type = opts[:content_type]

      @opts = opts
      @id = Utils.make_worker_id(self.class.name)
    end

    def reject!; :reject; end
    def requeue!; :requeue; end

    def run
      worker_trace "New worker: #{self.class} running."
      consumer = Nsq::Consumer.new(opts)
      loop do 
        msg = consumer.pop
        do_work(msg)
        msg.finish
      end
    end

    def publish(msg, opts)
      topic = opts.delete(:topic)
      producer = Nsq::Producer.new(opts[:nsqlookupd], topic)
      producer.write(msg)
    end


    def do_work(msg)
      worker_trace "Working off: #{msg.data.inspect} #{msg.body}"

      @pool.post do
        process_work(msg)
      end
    end

    def process_work(msg)
      begin
        work(msg)
      rescue StandardError, ScriptError => ex
        worker_error(ex, log_msg: log_msg(msg), class: self.class.name, message: msg)
      end
    end

    def stop
      worker_trace "Stopping worker: shutting down thread pool."
      @pool.shutdown
      @pool.wait_for_termination
      worker_trace "Stopping worker: I'm gone."
    end
    # Construct a log message with some standard prefix for this worker
    #
    def log_msg(msg)
      "[#{@id}][#{Thread.current}][#{self.class.name}] #{msg}"
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

      def from(opts={})
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
