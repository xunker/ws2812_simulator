module Ws2812Simulator::Simulations
  class Channel
    attr_accessor :gpionum, :invert, :brightness, :leds
    attr_reader :count
    attr_reader :display

    # leds_obj: Ws2811_t object
    def initialize(leds_obj, channel_number)
      @leds = leds_obj
      @channel = channel_number
    end

    def count=(val)
      @count = val
      @leds.count = val
    end
  end
end