class Nsqcd::Queue
  attr_reader :name, :opts, :topic

  def initialize(name, opts)
    @name = name
    @opts = opts
    @handler_klass = Nsqcd::CONFIG[:handler]
  end

  def publish(topic, msg)
    producer = Nsq::Producer.new(@opts[:nsqlookupd], topic)
    producer.write(msg)
  end
end
