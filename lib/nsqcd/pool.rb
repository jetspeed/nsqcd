module Nsqcd
  class Pool
    def initialize(opts = {})
      @mutex = Mutex.new
      @opts = Nsqcd::CONFIG.merge(opts)
      @pools = {}
      create!
    end

    def create!
      @opts[:topics].each do |topic|
        pool = ConnectionPool.new(size: 5, timeout: 5) { Nsq::Producer.new(@opts.merge(topic: topic)) }
        pool.with{|c| c.connected?}
        @pools[topic] = pool
      end
    end

    def get(topic) 
      @pools[topic]
    end
  end
end
