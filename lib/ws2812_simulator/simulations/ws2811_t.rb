module Ws2812Simulator::Simulations
  class Ws2811_t
    attr_accessor :freq, :dmanum
    attr_reader :count, :display_pid
    # attr_accessor :display_options, :display_socket
    attr_accessor :display_options, :to_server, :to_client
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
      return if @display_started

      puts "Please start the display server using this command:"
      cmd = "ws2811_server --count #{count}"
      cmd << ' --unicorn-hat' if @display_options[:arrangement] == :unicorn_hat
      cmd << ' --include-labels' if @display_options[:include_labels]

      puts "\t#{cmd}"

      server_message = ''
      last_message = 0#Process.clock_gettime(Process::CLOCK_REALTIME)
      attempts_remaining = 100
      puts 'waiting for display to start...'

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

          Ws2812Simulator::Communication.send_to_server Ws2812Simulator::Display::START_REQUEST
          puts "waiting for server connect response"
          server_message = Ws2812Simulator::Communication.read_from_server
          puts "response: #{server_message}"

        rescue Errno::ECONNREFUSED
          sleep 0.25
        end
      end

      Ws2812Simulator::Communication.send_to_server "count #{count}"
      puts Ws2812Simulator::Communication.read_from_server

      Ws2812Simulator::Communication.send_to_server "arrangement #{@display_options[:arrangement]}"
      puts Ws2812Simulator::Communication.read_from_server

      @display_started = true
    end

    def stop_display!
      Process.kill(:TERM, @display_pid) if @display_pid
    end
  end
end