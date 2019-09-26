module Nsqcd 
  module Metrics
    class LoggingMetrics
      def increment(metric)
        Nsqcd.logger.info("INC: #{metric}")
      end

      def timing(metric, &block)
        start = Time.now
        block.call
        Nsqcd.logger.info("TIME: #{metric} #{Time.now - start}")
      end
    end
  end
end

