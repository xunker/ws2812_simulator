module Ws2812Simulator::Simulations
  class Ws2811_t
    attr_accessor :freq, :dmanum
    attr_reader :count, :display_pid
    attr_accessor :display_options
    attr_accessor :ipc_pipe
    
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
      return if @display_pid

      if RbConfig::CONFIG['host_os'] =~ /darwin/ && ENV['OBJC_DISABLE_INITIALIZE_FORK_SAFETY'] !~ /yes/i
        warn "\n
        MacOS/Darwin detected. You probably need the OBJC_DISABLE_INITIALIZE_FORK_SAFETY
        environment variable set to 'YES' for this to work properly. Either set it on 
        the same line as the command:
       
        $ OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES ruby <.rb file path>
       
        ..or export the variable in your shell:
       
        $ export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
        $ ruby <.rb file path>
        "
      end

      @ipc_pipe = { from_display: Cod.pipe, to_display:  Cod.pipe }
      
      @display_pid = fork do
        display = Ws2812Simulator::Display.new(count: count, arrangement: @display_options[:arrangement], include_labels: @display_options[:include_labels], ipc_pipe: @ipc_pipe)
        display.show
      end

      display_message = ''
      until (display_message = @ipc_pipe[:from_display].get) == Ws2812Simulator::Display::STARTED_MESSAGE
        puts 'waiting for display to start...'
      end
    end

    def stop_display!
      Process.kill(:TERM, @display_pid) if @display_pid
    end
  end    
end