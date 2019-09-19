require 'serverengine'
require 'nsqcd/workergroup'

module Nsqcd
  class Runner
    def initialize(worker_classes, opts={})
      @runnerconfig = RunnerConfig.new(worker_classes, opts)
    end

    def run
      @se = ServerEngine.create(nil, WorkerGroup) { @runnerconfig.reload_config! }
      @se.run
    end

    def stop
      @se.stop
    end
  end


  class RunnerConfig
    def method_missing(meth, *args, &block)
      if %w{ before_fork after_fork }.include? meth.to_s
        @conf[meth] = block
      elsif %w{ workers start_worker_delay amqp }.include? meth.to_s
        @conf[meth] = args.first
      else
        super
      end
    end

    def initialize(worker_classes, opts)
      @worker_classes = worker_classes
      @conf = opts
    end

    def to_h
      @conf
    end


    def reload_config!
      Nsqcd.logger.info("Loading runner configuration...")
      config_file = Nsqcd::CONFIG[:runner_config_file]

      if config_file
        begin
          instance_eval(File.read(config_file), config_file)
          Nsqcd.logger.info("Loading config with file: #{config_file}")
        rescue
          Nsqcd.logger.error("Cannot load from file '#{config_file}', #{$!}")
        end
      end

      config = make_serverengine_config

      [:before_fork, :after_fork].each do | hook |
        Nsqcd::CONFIG[:hooks][hook] = config.delete(hook) if config[hook]
      end

      Nsqcd.logger.debug("New configuration: #{config.inspect}")
      config
    end

    private

    def make_serverengine_config
      # From Nsqcd#setup_general_logger, there's support for a Logger object
      # in CONFIG[:log].  However, serverengine takes an object in :logger.
      # Pass our logger object so there's no issue about sometimes passing a
      # file and sometimes an object.
      serverengine_config =  Nsqcd::CONFIG.merge(@conf)
      serverengine_config.merge!(
        :logger => Nsqcd.logger,
        :log_level => Nsqcd.logger.level,
        :worker_type => 'process',
        :worker_classes => @worker_classes,

        # Turning off serverengine internal logging infra, causes
        # livelock and hang.
        # see https://github.com/jondot/nsqcd/issues/153
        :log_stdout => false,
        :log_stderr => false
      )
      serverengine_config.delete(:log)

      serverengine_config
    end
  end

end
