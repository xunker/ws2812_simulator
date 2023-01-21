class Ws2812Simulator::Basic
  class Ws2811_t
    attr_accessor :freq, :dmanum
    attr_reader :count, :display
    
    def initialize
      # array of all the current LED values
      @leds = []  
    end

    def count=(val)
      @leds = Array.new(val) { 4294967295 } if @count != val
      @count = val
    end

    # each value is a uint32_t, containing the packed RGBA values
    def [](idx)
      @leds[idx]
    end

    def start_display!
      return if @display
      @display = Ws2812Simulator::Display.new(count: count).show
    end
  end

  class SimulatedChannel
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

  module Simulations
    # returns 0 (success) or non-zero (error)
    def ws2811_init(leds_obj)
      0
    end

    def ws2811_channel_get(leds_obj, channel_number)
      SimulatedChannel.new(leds_obj, channel_number)
    end
    
    def ws2811_led_set(_channel, index, color_int)
      puts "ws2811_led_set(#{_channel.class}, #{index.inspect}, #{Ws2812Simulator::Color.from_i(color_int).inspect})"
    end
    
    def ws2811_render(leds_obj)
      puts "ws2811_render(#{leds_obj.inspect})"
      # if !leds_obj.display
      #   leds_obj.start_display!
      # end

      0 # everything OK
    end
    
    # uint32_t ws2811_led_get(ws2811_channel_t *channel, int lednum)
    def ws2811_led_get(channel, lednum)
      return -1 if (lednum >= channel.count)
      channel.leds[lednum]
    end

    # Shut down DMA, PWM, and cleanup memory.
    # void ws2811_fini(ws2811_t *ws2811)
    def ws2811_fini(leds_obj)
      # no-op for now
    end
  end
end