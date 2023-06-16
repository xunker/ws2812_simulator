require 'simple-fifo'
require 'io/wait' # for .ready? call on IO obj
require 'singleton'
require 'forwardable'

module Ws2812Simulator
  class Communication
    include Singleton
    class << self
      extend Forwardable
      def_delegators :instance,
        :send_to_server, :send_to_client, :read_from_server, :read_from_client,
        :message_waiting_from_client?, :message_waiting_from_server?,
        :send_shutdown_to_client!,
        :send_ok_to_client,
        :send_error_to_client,
        :send_stop_to_server!
    end

    TO_SERVER_FIFO = './to_server.fifo'
    TO_CLIENT_FIFO = './to_client.fifo'

    SHUTDOWN_MESSAGE = 'shutdown'
    OK_MESSAGE = 'ok'
    ERROR_MESSAGE = 'error'
    STOP_MESSAGE = 'stop'

    def send_to_server(message)
      to_server.puts(message)
    end

    def send_to_client(message)
      to_client.puts(message)
    end

    def read_from_server
      from_server.gets.strip.tap{|msg|
        if msg == SHUTDOWN_MESSAGE
          puts '*** server is shutting down ***'
          exit 1
        elsif msg.match?(/^#{ERROR_MESSAGE}/)
          puts "Server returned error: #{msg}"
          exit 1
        end
      }
    end

    def read_from_client
      from_client.gets.strip
    end

    def message_waiting_from_client?
      @from_client_io ||= from_client.to_io
      @from_client_io.ready?
    end

    def message_waiting_from_server?
      @from_server_io ||= from_server.to_io
      @from_server_io.ready?
    end

    def send_shutdown_to_client!
      send_to_client SHUTDOWN_MESSAGE
    end

    def send_stop_to_server!
      send_to_server STOP_MESSAGE
    end

    def send_ok_to_client
      send_to_client OK_MESSAGE
    end

    def send_error_to_client(message = nil)
      body = ERROR_MESSAGE
      body << " #{message}" if !message.nil?
      send_to_client body
    end

    private

    def to_server
      @to_server ||= Fifo.new(TO_SERVER_FIFO, :w, :nowait)
    end

    def to_client
      @to_client ||= Fifo.new(TO_CLIENT_FIFO, :w, :nowait)
    end

    def from_server
      @from_server ||= Fifo.new(TO_CLIENT_FIFO, :r, :nowait)
    end

    def from_client
      @from_client ||= Fifo.new(TO_SERVER_FIFO, :r, :nowait)
    end
  end
end