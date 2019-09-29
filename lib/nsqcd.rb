require 'nsqcd/version'
require 'logger'
require 'serverengine'

module Nsqcd
  module Handlers
  end
  module Concerns
  end
end

require 'nsqcd/configuration'
require 'nsqcd/errors'
require 'nsqcd/support/production_formatter'
require 'nsqcd/concerns/logging'
require 'nsqcd/worker'

module Nsqcd
  extend self

  CONFIG = Configuration.new

  def configure(opts={})
    # worker > userland > defaults
    CONFIG.merge!(opts)
    setup_general_logger!
    setup_worker_concerns!
    @configured = true
  end

  def clear!
    CONFIG.clear
    @logger = nil
    @configured = false
  end

  def daemonize!(loglevel=Logger::INFO)
    CONFIG[:log] = 'nsqcd.log'
    CONFIG[:daemonize] = true
    setup_general_logger!
    logger.level = loglevel
  end

  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger
  end

  def configured?
    @configured
  end

  def server=(server)
    @server = server
  end

  def server?
    @server
  end

  def configure_server
    yield self if server?
  end

  # Register a proc to handle any error which occurs within the Nsqcd process.
  #
  #   Nsqcd.error_reporters << proc { |exception, worker, context_hash| MyErrorService.notify(exception, context_hash) }
  #
  # The default error handler logs errors to Nsqcd.logger.
  # Ripped off from https://github.com/mperham/sidekiq/blob/6ad6a3aa330deebd76c6cf0d353f66abd3bef93b/lib/sidekiq.rb#L165-L174
  def error_reporters
    CONFIG[:error_reporters]
  end

  private

  def setup_general_logger!
    if [:info, :debug, :error, :warn].all?{ |meth| CONFIG[:log].respond_to?(meth) }
      @logger = CONFIG[:log]
    else
      @logger = ServerEngine::DaemonLogger.new(CONFIG[:log])
      @logger.formatter = Nsqcd::Support::ProductionFormatter
    end
  end

  def setup_worker_concerns!
    Worker.configure_logger(Nsqcd::logger)
  end
end

