require 'ruby2d'

module Ws2812Simulator
  class Display
    class Led
      DEFAULT_COLOR = [0.0, 0.0, 0.0, 1.0] # r, g, b, a

      HEX_TO_FLOAT_CONVERSION_CONSTANT = (1.0 / 255.0)

      attr_reader :number, :obj, :text, :r, :g, :b, :alpha, :string
      attr_accessor :data, :events
      def initialize(string, number, obj, text = nil)
        @string = string
        @number = number
        @obj = obj
        @text = text
        @obj.color = DEFAULT_COLOR
        @r = 0.0
        @g = 0.0
        @b = 0.0
        @alpha = 1.0
        @data = {}
        @events = []
      end

      def set_color(r: nil, g: nil, b: nil, a: nil)
        @r = hex_to_float(r, default: @r)
        @g = hex_to_float(g, default: @g)
        @b = hex_to_float(b, default: @b)
        @alpha = hex_to_float(a, default: @alpha)
        @string.leds_dirty!
        get_color
      end

      def get_color(include_alpha: true)
        { r: @r, g: @g, b: @b, a: (include_alpha ? @alpha : nil) }.compact
      end

      def hex_to_float(hex_val, default:)
        return default unless hex_val
        hex_val.to_f * HEX_TO_FLOAT_CONVERSION_CONSTANT
      end
    end

    START_REQUEST = 'start'
    STARTED_MESSAGE = 'started'

    attr_accessor :leds_dirty, :update_requested
    attr_reader :window, :leds, :count, :arrangement

    def debug(message)
      return unless @verbose
      puts message
    end

    def initialize(count:,
      width: 320, height: 240,
      arrangement: :default, include_labels: false,
      verbose: false, obey_client_stop: false)
      @count = count
      @update_leds = false
      @arrangement = arrangement
      @include_labels = include_labels
      @verbose = verbose
      @obey_client_stop = obey_client_stop

      @window = Ruby2D::Window.new

      # @tick is only here to provide `print` fodder during window.update
      @tick = 0

      @window.set(
        title: "WS2812 Simulator",
        width: width,
        height: height,
        fps_cap: 60*2,
        background: [0.5, 0.5, 0.5, 0.5]
      )

      set_leds

      window.on :key do |e|
        if e.type == :down
          case e.key
          when 'q'
            Communication.send_shutdown_to_client!
            window.close
          end
        end
      end

      window.update do

        verbose_output = []

        received_message_type = nil
        if Communication.message_waiting_from_client?
          client_messages = Communication.read_from_client
          debug "processing: #{client_messages.inspect}"
          client_messages.split(Communication::BUFFERED_MESSAGE_DELIMITER).each do |client_message|
            received_message_type = client_message[0].upcase

            debug "message: #{client_message.inspect}"
            if client_message == START_REQUEST
              debug "sending #{STARTED_MESSAGE}"
              Communication.send_to_client STARTED_MESSAGE
            elsif client_message =~ /^count/
              _cmd, new_count = client_message.split(/\s+/)
              new_count = new_count.to_i
              debug "existing count: #{@count.inspect}"
              if @count != new_count
                debug "new led count: #{new_count.inspect}"
                @count = new_count

                reset_leds
              end

              Communication.send_ok_to_client

            elsif client_message =~ /^arrangement/
              _cmd, new_arrangement = client_message.split(/\s+/)
              new_arrangement = new_arrangement.to_sym
              debug "existing arrangement: #{@arrangement.inspect}"
              if @arrangement != new_arrangement
                debug "new led arrangement: #{new_arrangement.inspect}"
                @arrangement = new_arrangement

                reset_leds
              end
              Communication.send_ok_to_client
            elsif client_message =~ /^led/
              _cmd, led_index, led_color_int = client_message.split(/\s+/)
              # the 'led' message does not usually expect an ok to be sent because it may be batched
              # Communication.send_ok_to_client
              color = Color.from_i(led_color_int.to_i)
              @leds[led_index.to_i].set_color(r: color.r, g: color.g, b: color.b)
            elsif client_message == Communication::STOP_MESSAGE
              Communication.send_ok_to_client
              if @obey_client_stop
                warn 'Received stop from client, shutting down'
                @window.close
                exit 1
              else
                warn 'Received stop from client, but will keep display running'
              end
            elsif client_message == Communication::RENDER_MESSAGE
              Communication.send_ok_to_client
              update_requested!
            else
              debug "Error: #{client_message.inspect}"
              received_message_type = 'E'
              Communication.send_error_to_client "unknown command #{client_message.inspect}"
            end
          end
        end

        if leds_dirty? && update_requested?
          update_leds
        end


        print received_message_type || '.'

        @tick += 1
        if @tick >= @count
          @tick = 0
          print "\r"
          $stdout.flush
        end
      end
    end

    def remove_leds
      if @leds
        @leds.each do |led|
          @window.remove(led.obj)
          @window.remove(led.text) if led.text
        end
      end
    end

    def reset_leds
      remove_leds
      set_leds
    end

    def set_leds
      leds_per_row =  Math.sqrt(count).ceil
      leds_per_column =  Math.sqrt(count).floor
      while (leds_per_row * leds_per_column) < @count
        leds_per_column += 1
      end

      led_d = [window.width / leds_per_row, window.height / leds_per_column].min

      width_per_led = window.width / leds_per_row
      height_per_led = window.height / leds_per_column

      @leds = []
      leds_per_column.times do |col_idx|
        leds_per_row.times do |row_idx|
          next if @leds.length >= count


          led_x_pos = (row_idx * width_per_led) + (width_per_led/2)
          if (arrangement == :unicorn_hat) && (col_idx % 2 == 0)
            # reverse direction on this row to emulate unicorn hat
            led_x_pos = window.width - led_x_pos
          end

          @leds << Led.new(
            self,
            @leds.length,
            Ruby2D::Circle.new(
              x: led_x_pos,
              y: (col_idx * height_per_led) + (led_d/2),
              radius: (led_d/2) * 0.9
            ),
            @include_labels ? Ruby2D::Text.new(
              @leds.length,
              x: led_x_pos,
              y: (col_idx * height_per_led) + (led_d/2),
              size: 10
            ) : nil
          )
        end
      end

      @leds.each do |led|
        window.add(led.obj)
        window.add(led.text) if led.text
      end
    end

    def update_leds
      @leds.each do |led|
        colors = led.get_color
        led.obj.color = %i[r g b a].map{|c| colors[c]}
        if led.text
          led.text.text = "#{led.number}: #{led.get_color.map{|k,v| v.round(1)}.join(' / ')}"
        end
      end

      @leds_dirty = false
    end

    def show
      puts "Display#show called!!"
      @window.show
    rescue SignalException => e
      Communication.send_shutdown_to_client!
      raise
    end

    def leds_dirty?
      !!leds_dirty
    end

    def leds_dirty!
      @leds_dirty = true
    end

    def update_requested?
      !!update_requested
    end

    def update_requested!
      @update_requested = true
    end
  end
end