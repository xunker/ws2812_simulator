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
    MAX_TICK = 25

    attr_accessor :leds_dirty, :update_requested
    attr_reader :window, :leds, :count, :arrangement

    # def initialize(count:, width: 800, height: 600, arrangement: :default, include_labels: false, ipc_pipe: nil)
    def initialize(count:, width: 800, height: 600, arrangement: :default, include_labels: false)
      @count = count
      @update_leds = false
      @arrangement = arrangement
      @include_labels = include_labels

      @window = Ruby2D::Window.new

      # @tick is only here to provide `print` fodder during window.update so threads are more responsive
      @tick = 0
      @tick_dir = 1 # or -1

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
            window.close
          end
        end
      end

      @to_server = Fifo.new('./to_server.fifo', :r, :nowait)
      @to_client = Fifo.new('./to_client.fifo', :w, :nowait)
      # @client_messages = []

      # Thread.new {
      #   loop do
      #     puts 'accepting'
      #     # thread within a thread so we can reuse the same server/socket better
      #     # from_client = @to_server.gets
      #     # puts "accepted: #{from_client.inspect}"

      #     # msg_len = from_client.slice!(0, 3)

      #     # msg_len = @to_server.read(3)
      #     # puts "msg_len: #{msg_len.inspect}"

      #     # msg_len = msg_len.to_i
      #     # message_done = false
      #     # while message_done == false
      #     #   # client_message = from_client.strip
      #     #   # client_message = @to_server.read(msg_len)
      #     #   message_done=true
      #     @client_messages << @to_server.gets.strip
      #     puts "CLIENT MESSAGE: #{@client_messages.last.inspect}"

      #   end
      # }

      # @server = TCPServer.new('localhost', 8999)
      # # @server.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      # @server.autoclose = false
      # Thread.new {
      #   loop do
      #     puts 'accepting'
      #     # thread within a thread so we can reuse the same server/socket better
      #     Thread.start(@server.accept) do |client|
      #       client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      #       puts 'accepted'
      #       loop do
      #         puts 'waiting for length'
      #         msg_len = client_message = client.recv(3)
      #         puts "msg_len: #{msg_len.inspect}"
      #         msg_len = msg_len.to_i
      #         message_done = false
      #         while message_done == false
      #         # loop do
      #           # client = @server.accept
      #           # client_message = ''
      #           # (msg_len).times { client_message << client.getc }
      #           client_message = client.recv(msg_len)
      #           message_done=true
      #           client_message.strip!
      #           puts "CLIENT MESSAGE: #{client_message.inspect}"
      #           if client_message == START_REQUEST
      #             # client.puts STARTED_MESSAGE
      #             puts "sending #{STARTED_MESSAGE}"
      #             client.write STARTED_MESSAGE
      #           elsif client_message =~ /^count/
      #             _cmd, new_count = client_message.split(/\s+/)
      #             new_count = new_count.to_i
      #             puts "existing count: #{@count.inspect}"
      #             if @count != new_count
      #               puts "new led count: #{new_count.inspect}"
      #               @count = new_count
      #               remove_leds
      #               set_leds#(@count)
      #             end

      #             client.write "OK"
      #           elsif client_message =~ /^led/
      #             _cmd, led_index, led_color_int = client_message.split(/\s+/)
      #             # client.puts "OK"
      #             client.write "OK"
      #             color = Color.from_i(led_color_int.to_i)
      #             @leds[led_index.to_i].set_color(r: color.r, g: color.g, b: color.b)
      #           else
      #             puts "Error: #{client_message.inspect}"
      #             # client.puts 'ER'
      #             client.write 'ER'
      #           end
      #         end
      #       end
      #       puts 'closing'
      #       client.close
      #       puts 'closed'
      #     end
      #     # puts client.inspect
      #   end
      # }

      # @rpc_server = Jimson::Server.new(RpcHandler.new, host: 'localhost', port: 8999, show_errors: true)
      # Thread.new {
      #   puts 'rpc started'
      #   @rpc_server.start
      #   puts 'rpc ended'
      # }

      window.update do
        # if ipc_pipe
        #   ipc_cmd = ipc_pipe[:to_display].get

        #   if ipc_cmd.to_s.length > 0 && ipc_cmd.first == :led
        #     color = ipc_cmd.last
        #     @leds[ipc_cmd[1]].set_color(r: color.r, g: color.g, b: color.b)
        #   end
        # end

        verbose_output = []
        # if (client_message = @client_messages.shift).to_s.length > 0
        if @to_server.to_io.ready?
          client_message = @to_server.gets.strip
          verbose_output << "UPDATE: processing #{client_message}"
          if client_message == START_REQUEST
            verbose_output << "sending #{STARTED_MESSAGE}"
            @to_client.puts STARTED_MESSAGE
          elsif client_message =~ /^count/
            _cmd, new_count = client_message.split(/\s+/)
            new_count = new_count.to_i
            verbose_output << "existing count: #{@count.inspect}"
            if @count != new_count
              verbose_output << "new led count: #{new_count.inspect}"
              @count = new_count
              remove_leds
              set_leds#(@count)
            end

            @to_client.puts "OK"
          elsif client_message =~ /^led/
            _cmd, led_index, led_color_int = client_message.split(/\s+/)
            @to_client.puts "OK"
            color = Color.from_i(led_color_int.to_i)
            @leds[led_index.to_i].set_color(r: color.r, g: color.g, b: color.b)
          else
            verbose_output << "Error: #{client_message.inspect}"
            @to_client.puts 'ER'
          end
        end

        # if update_requested? && leds_dirty?
        if leds_dirty?
          update_leds
        end

        if verbose_output.length > 0
          puts verbose_output.join("\n")
        else
          # @tick is only here to provide `print` fodder during window.update so threads are more responsive
          case @tick_dir
          when 1
            print '.'
          else
            print "\b" # backspace
          end
        end
        if @tick >= MAX_TICK
          @tick_dir = -1
        elsif @tick <= 0
          @tick_dir = 1
        end
        @tick += @tick_dir
      end

      # if ipc_pipe
      #   ipc_pipe[:from_display].put STARTED_MESSAGE
      # end
    end

    # class RpcHandler
    #   extend Jimson::Handler

    #   def sum(a,b)
    #     a + b
    #   end

    #   def start
    #     STARTED_MESSAGE
    #   end
    # end

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
      # require 'byebug'; byebug;
      # true
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