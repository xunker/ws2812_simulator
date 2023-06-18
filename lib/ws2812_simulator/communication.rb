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
        :send_stop_to_server!,
        :buffer_client_to_server?,
        :buffer_client_to_server!
    end

    TO_SERVER_FIFO = './to_server.fifo'
    TO_CLIENT_FIFO = './to_client.fifo'

    SHUTDOWN_MESSAGE = 'shutdown'
    OK_MESSAGE = 'ok'
    ERROR_MESSAGE = 'error'
    STOP_MESSAGE = 'stop'
    RENDER_MESSAGE = 'render'

    CLIENT_TO_SERVER_BUFFER_LENGTH = 20

    BUFFERED_MESSAGE_DELIMITER = ';'

    @@buffer_client_to_server = true
    @@client_to_server_buffer = []

    def send_to_server(message)
      @@client_to_server_buffer << message

      do_not_buffer_client_to_server = !buffer_client_to_server?
      buffer_past_threshold = @@client_to_server_buffer.length >= CLIENT_TO_SERVER_BUFFER_LENGTH
      is_immediate_send_message = immediate_send_message?(message)

      send_buffer_now = [
        do_not_buffer_client_to_server,
        buffer_past_threshold,
        is_immediate_send_message
      ].any?

      if send_buffer_now
        to_server.puts @@client_to_server_buffer.join(BUFFERED_MESSAGE_DELIMITER)
        to_server.flush
        @@client_to_server_buffer = []
      end
    end

    def immediate_send_message?(message)
      message.split(/\s+/).first != 'led'
    end

    def send_to_client(message)
      to_client.puts(message)
      to_client.flush
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

    def send_render_to_server!
      send_to_server RENDER_MESSAGE
    end

    def send_ok_to_client
      send_to_client OK_MESSAGE
    end

    def send_error_to_client(message = nil)
      body = ERROR_MESSAGE
      body << " #{message}" if !message.nil?
      send_to_client body
    end

    def buffer_client_to_server?
      @@buffer_client_to_server
    end

    def buffer_client_to_server!(mode = true)
      @@buffer_client_to_server = !!mode
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