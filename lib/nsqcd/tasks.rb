require 'nsqcd'
require 'nsqcd/runner'

task :environment

namespace :nsqcd do
  desc "Start work (set $WORKERS=Klass1,Klass2)"
  task :run do
    Nsqcd.server = true
    Rake::Task['environment'].invoke

    if defined?(::Rails)
      ::Rails.application.eager_load!
    end

    if ENV["WORKERS"].nil?
      workers = Nsqcd::Worker::Classes
    else
      workers, missing_workers = Nsqcd::Utils.parse_workers(ENV['WORKERS'])
    end

    unless missing_workers.nil? || missing_workers.empty?
      puts "Missing workers: #{missing_workers.join(', ')}" if missing_workers
      puts "Did you `require` properly?"
      exit(1)
    end

    if workers.empty?
      puts <<EOF
Error: No workers found.
Please set the classes of the workers you want to run like so:

  $ export WORKERS=MyWorker,FooWorker
  $ rake nsqcd:run

EOF
      exit(1)
    end
    opts = (!ENV['WORKER_COUNT'].nil? ? {:workers => ENV['WORKER_COUNT'].to_i} : {})
    r = Nsqcd::Runner.new(workers, opts)

    r.run
  end
end
