module Ws2812Simulator::Simulations
  class Ws2811_t
    attr_accessor :freq, :dmanum
    attr_reader :count, :display_pid
    attr_accessor :display_options, :display_socket
    # attr_accessor :ipc_pipe

    def initialize
      # array of all the current LED values
      @leds = []
      @display_options = {}
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
      # return if @display_pid
      return if @display_started

      # if RbConfig::CONFIG['host_os'] =~ /darwin/ && ENV['OBJC_DISABLE_INITIALIZE_FORK_SAFETY'] !~ /yes/i
      #   warn "\n
      #   MacOS/Darwin detected. You probably need the OBJC_DISABLE_INITIALIZE_FORK_SAFETY
      #   environment variable set to 'YES' for this to work properly. Either set it on
      #   the same line as the command:

      #   $ OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES ruby <.rb file path>

      #   ..or export the variable in your shell:

      #   $ export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
      #   $ ruby <.rb file path>
      #   "
      # end

      # @ipc_pipe = { from_display: Cod.pipe, to_display:  Cod.pipe }

      # @display_pid = fork do
      #   display = Ws2812Simulator::Display.new(count: count, arrangement: @display_options[:arrangement], include_labels: @display_options[:include_labels], ipc_pipe: @ipc_pipe)
      #   display.show
      # end

      puts "Please start the display server using this command:"
      cmd = "ws2811_server --count #{count}"
      cmd << ' --unicorn-hat' if @display_options[:arrangement] == :unicorn_hat
      cmd << ' --include-labels' if @display_options[:include_labels]

      puts "\t#{cmd}"

      # display_message = ''
      # display_message = @ipc_pipe[:from_display].get) == Ws2812Simulator::Display::STARTED_MESSAGE
      #   puts 'waiting for display to start...'
      # end

      # Errno::ECONNREFUSED

      # server_message = ''
      # last_message = 0#Process.clock_gettime(Process::CLOCK_REALTIME)
      # attempts_remaining = 100
      # puts 'waiting for display to start...'
      # until server_message == Ws2812Simulator::Display::STARTED_MESSAGE
      #   begin
      #     current_timestamp = Process.clock_gettime(Process::CLOCK_REALTIME)
      #     if last_message < current_timestamp - 1
      #       last_message = current_timestamp
      #     end

      #     if (attempts_remaining -= 1) <= 0
      #       puts 'could not connect to server.'
      #       exit 0
      #     end

      #     print '.'

      #     puts '' if (attempts_remaining % 25) == 0

      #     @rpc_client = Jimson::Client.new("http://localhost:8999")
      #     server_message = @rpc_client.start
      #   rescue Errno::ECONNREFUSED
      #     sleep 0.25
      #   end
      # end

      server_message = ''
      last_message = 0#Process.clock_gettime(Process::CLOCK_REALTIME)
      attempts_remaining = 100
      puts 'waiting for display to start...'

      @display_socket = TCPSocket.new('localhost', 8999); @display_socket.autoclose=false
      until server_message == Ws2812Simulator::Display::STARTED_MESSAGE
        begin
          current_timestamp = Process.clock_gettime(Process::CLOCK_REALTIME)
          if last_message < current_timestamp - 1
            last_message = current_timestamp
          end

          if (attempts_remaining -= 1) <= 0
            puts 'could not connect to server.'
            exit 0
          end

          print '.'

          puts '' if (attempts_remaining % 25) == 0

          # @display_socket = TCPSocket.new('localhost', 8999); @display_socket.autoclose=false

          # @display_socket.puts Ws2812Simulator::Display::START_REQUEST
          # @display_socket.send "#{Ws2812Simulator::Display::START_REQUEST.length.to_s.rjust(3, '0')}#{Ws2812Simulator::Display::START_REQUEST}\000", 0
          @display_socket.write "#{Ws2812Simulator::Display::START_REQUEST.length.to_s.rjust(3, '0')}#{Ws2812Simulator::Display::START_REQUEST}"
          # server_message = @display_socket.gets.strip
          server_message = @display_socket.read(Ws2812Simulator::Display::STARTED_MESSAGE.length)

        rescue Errno::ECONNREFUSED
          sleep 0.25
        end
      end
      msg = "count #{count}"
      @display_socket.write "#{msg.length.to_s.rjust(3, '0')}#{msg}"
      server_message = @display_socket.read(2)



      @display_started = true
    end

    def stop_display!
      Process.kill(:TERM, @display_pid) if @display_pid
    end
  end
end