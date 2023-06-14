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

      # channel.leds.ipc_pipe[:to_display].put [:led, index, Ws2812Simulator::Color.from_i(color_int)]
      # channel.leds.display_socket.puts "led #{index} #{Ws2812Simulator::Color.from_i(color_int)}"

      # channel.leds.display_socket.puts "led #{index} #{color_int}"
      msg = "led #{index} #{color_int}"
      msg = "#{msg.length.to_s.rjust(3, '0')}led #{index} #{color_int}"
      # channel.leds.display_socket.send(msg, 0)
      channel.leds.display_socket.write(msg)
      # puts channel.leds.display_socket.gets
      server_message = channel.leds.display_socket.read(2)
      puts "response: #{server_message}"
    end

    def ws2811_render(ws2811_t)
      # puts "ws2811_render(#{ws2811_t.inspect})"

      ws2811_t.start_display!

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