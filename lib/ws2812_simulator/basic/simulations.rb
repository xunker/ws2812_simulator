require_relative '../simulations/ws2811_t'
require_relative '../simulations/channel'
class Ws2812Simulator::Basic
  module Simulations
    # returns 0 (success) or non-zero (error)
    def ws2811_init(ws2811_t)
      ws2811_t.start_display!
      0
    end

    def ws2811_channel_get(ws2811_t, channel_number)
      Ws2812Simulator::Simulations::Channel.new(ws2811_t, channel_number)
    end

    def ws2811_led_set(channel, index, color_int)
      # puts "ws2811_led_set(#{channel.class}, #{index.inspect}, #{Ws2812Simulator::Color.from_i(color_int).inspect})"
      msg = "led #{index} #{color_int}"
      # puts "send: #{msg}"
      Ws2812Simulator::Communication.send_to_server msg
      # 'led' message does not expect a response from the server because it may be batched
    end

    # returns 0 (success) or non-zero (error)
    def ws2811_render(ws2811_t)
      Ws2812Simulator::Communication.send_to_server 'render'
      server_message = Ws2812Simulator::Communication.read_from_server
      # puts "render response: #{server_message}"
      0 # everything OK
    end

    # uint32_t ws2811_led_get(ws2811_channel_t *channel, int lednum)
    def ws2811_led_get(channel, lednum)
      return -1 if (lednum >= channel.count)
      channel.leds[lednum]
    end

    # Shut down DMA, PWM, and cleanup memory.
    # void ws2811_fini(ws2811_t *ws2811)
    def ws2811_fini(ws2811_t)
      ws2811_t.stop_display!
    end
  end
end