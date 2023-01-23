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

    STARTED_MESSAGE = 'started'

    attr_accessor :leds_dirty
    attr_reader :window, :leds, :count, :arrangement

    def initialize(count:, width: 800, height: 600, arrangement: :default, include_labels: false, ipc_pipe: nil)
      @count = count
      @update_leds = false
      @arrangement = arrangement
      @include_labels = include_labels

      @window = Ruby2D::Window.new
      window.set(
        title: "WS2812 Simulator - #{count} LEDs",
        width: width,
        height: height,
        fps: 60,
        background: [0.5, 0.5, 0.5, 0.5]
      )

      set_leds
    
      window.on :key do |e|
        if e.type == :down
          case e.key
          when 'q'
            window.close
          end
        end
      end

      window.update do
        if ipc_pipe
          ipc_cmd = ipc_pipe[:to_display].get
          
          if ipc_cmd.to_s.length > 0 && ipc_cmd.first == :led
            color = ipc_cmd.last
            @leds[ipc_cmd[1]].set_color(r: color.r, g: color.g, b: color.b)
          end
        end

        if leds_dirty?
          update_leds
        end
      end

      if ipc_pipe
        ipc_pipe[:from_display].put STARTED_MESSAGE
      end
    end

    def set_count(val)
      return if val == @count

      if @leds
        @leds.each do |led|
          @window.remove(led.obj)
          @window.remove(led.text) if led.text
        end
      end

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
      @window.show
      # require 'byebug'; byebug;
      # true
    end

    def leds_dirty?
      !!leds_dirty
    end

    def leds_dirty!
      @leds_dirty = true
    end
  end
end