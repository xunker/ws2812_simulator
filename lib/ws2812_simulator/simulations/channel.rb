module Ws2812Simulator::Simulations
  class Channel
    attr_accessor :gpionum, :invert, :brightness, :leds
    attr_reader :count
    attr_reader :display

    def initialize(ws2811_t, channel_number)
      @leds = ws2811_t
      @channel = channel_number
    end

    def count=(val)
      @count = val
      @leds.count = val
    end
  end
end