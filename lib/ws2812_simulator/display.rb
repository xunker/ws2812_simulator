require 'ruby2d'

module Ws2812Simulator
  class Display
    class Led
      DEFAULT_COLOR = [0.0, 0.0, 0.0, 1.0]

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
        @r = r || @r
        @g = g || @g
        @b = b || @b
        @alpha = a || @alpha
        @string.leds_dirty!
        get_color
      end

      def get_color(include_alpha: true)
        { r: @r, g: @g, b: @b, a: (include_alpha ? @alpha : nil) }.compact
      end
    end

    START_REQUEST = 'start'
    STARTED_MESSAGE = 'started'

    attr_accessor :leds_dirty, :update_requested
    attr_reader :window, :leds, :count, :arrangement

    # def initialize(count:, width: 800, height: 600, arrangement: :default, include_labels: false, ipc_pipe: nil)
    def initialize(count:, width: 640, height: 480, arrangement: :default, include_labels: false, verbose: false)
      @count = count
      @update_leds = false
      @arrangement = arrangement
      @include_labels = include_labels
      @verbose = verbose

      @window = Ruby2D::Window.new

      # @tick is only here to provide `print` fodder during window.update
      @tick = 0

      @window.set(
        title: "WS2812 Simulator",
        width: width,
        height: height,
        fps_cap: 60,
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
          client_message = Communication.read_from_client
          received_message_type = client_message[0].upcase

          verbose_output << "UPDATE: processing #{client_message}"
          if client_message == START_REQUEST
            verbose_output << "sending #{STARTED_MESSAGE}"
            Communication.send_to_client STARTED_MESSAGE
          elsif client_message =~ /^count/
            _cmd, new_count = client_message.split(/\s+/)
            new_count = new_count.to_i
            verbose_output << "existing count: #{@count.inspect}"
            if @count != new_count
              verbose_output << "new led count: #{new_count.inspect}"
              @count = new_count
              remove_leds
              set_leds
            end

            Communication.send_to_client "OK"

          elsif client_message =~ /^arrangement/
            _cmd, new_arrangement = client_message.split(/\s+/)
            new_arrangement = new_arrangement.to_sym
            verbose_output << "existing arrangement: #{@arrangement.inspect}"
            if @arrangement != new_arrangement
              verbose_output << "new led arrangement: #{new_arrangement.inspect}"
              @arrangement = new_arrangement
              remove_leds
              set_leds
            end
            Communication.send_to_client "OK"
          elsif client_message =~ /^led/
            _cmd, led_index, led_color_int = client_message.split(/\s+/)
            Communication.send_to_client "OK"
            color = Color.from_i(led_color_int.to_i)
            @leds[led_index.to_i].set_color(r: color.r, g: color.g, b: color.b)
          else
            verbose_output << "Error: #{client_message.inspect}"
            received_message_type = 'E'
            Communication.send_to_client 'ER'
          end
        end

        if leds_dirty?
          update_leds
        end

        if @verbose && verbose_output.length > 0
          puts verbose_output.join("\n")
        else
          print received_message_type || '.'
        end
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

    def set_count(val)
      return if val == @count

      remove_leds

      @count = val
      set_leds
    end

    def set_leds
      leds_per_row =  Math.sqrt(count).ceil
      leds_per_column =  Math.sqrt(count).floor

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