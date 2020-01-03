module Nsqcd
  class Producer
    def method_missing(method, *args, &block)
      @pl.with{|c| c.send(method, *args, &block)}
    end
    def initialize(topic)
      Nsqcd.init! unless $pool
      @pl = $pool.get(topic)
    end

    def terminate
    end
  end
end
