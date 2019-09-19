module Nsqcd
  module ErrorReporter
    class DefaultLogger
      def call(exception, worker, context_hash)
        Nsqcd.logger.warn(context_hash) unless context_hash.empty?
        log_string = ''
        log_string += "[Exception error=#{exception.message.inspect} error_class=#{exception.class} worker_class=#{worker.class}"  unless exception.nil?
        log_string += " backtrace=#{exception.backtrace.take(50).join(',')}" unless exception.nil? || exception.backtrace.nil?
        log_string += ']'
        Nsqcd.logger.error log_string
      end
    end

    def worker_error(exception, context_hash = {})
      Nsqcd.error_reporters.each do |handler|
        begin
          handler.call(exception, self, context_hash)
        rescue => inner_exception
          Nsqcd.logger.error '!!! ERROR REPORTER THREW AN ERROR !!!'
          Nsqcd.logger.error inner_exception
          Nsqcd.logger.error inner_exception.backtrace.join("\n") unless inner_exception.backtrace.nil?
        end
      end
    end
  end
end
