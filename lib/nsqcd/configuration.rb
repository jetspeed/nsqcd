require 'nsqcd/error_reporter'
require 'forwardable'

module Nsqcd
  class Configuration

    extend Forwardable
    def_delegators :@hash, :to_hash, :[], :[]=, :==, :fetch, :delete, :has_key?

    QUEUE_OPTION_DEFAULTS = {
      topic: 'the-topic',
      channel: 'my-channel',
      nsqlookupd: ['127.0.0.1:4161', '4.5.6.7:4161'],
      max_in_flight: 100,
      discovery_interval: 30,
      msg_timeout: 120_000,
      max_attempts: 10
    }.freeze

    DEFAULTS = {
      # Set up default handler which just logs the error.
      # Remove this in production if you don't want sensitive data logged.
      :error_reporters => [Nsqcd::ErrorReporter::DefaultLogger.new],

      # runner
      :runner_config_file => nil,
      :metrics            => nil,
      :daemonize          => false,
      :start_worker_delay => 0.2,
      :workers            => 2,
      :heartbeat          => 30,
      :log                => STDOUT,
      :pid_path           => 'nsqcd.pid',

      # workers
      :prefetch           => 10,
      :threads            => 10,
      :share_threads      => false,
      :ack                => true,
      :hooks              => {},
      :queue_options      => QUEUE_OPTION_DEFAULTS
    }.freeze


    def initialize
      clear
    end

    def clear
      @hash = DEFAULTS.dup
    end

    def merge!(hash)
      hash = hash.dup
      @hash = deep_merge(@hash, hash)
    end

    def merge(hash)
      instance = self.class.new
      instance.merge! to_hash
      instance.merge! hash
      instance
    end

    def deep_merge(first, second)
      merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      first.merge(second, &merger)
    end
  end
end
