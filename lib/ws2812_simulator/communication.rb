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
        :message_waiting_from_client?, :message_waiting_from_server?
    end

    def send_to_server(message)
      to_server.puts(message)
    end

    def send_to_client(message)
      to_client.puts(message)
    end

    def read_from_server
      from_server.gets.strip
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

    private

    def to_server
      @to_server ||= Fifo.new('./to_server.fifo', :w, :nowait)
    end

    def to_client
      @to_client ||= Fifo.new('./to_client.fifo', :w, :nowait)
    end

    def from_server
      @from_server ||= Fifo.new('./to_client.fifo', :r, :nowait)
    end

    def from_client
      @from_client ||= Fifo.new('./to_server.fifo', :r, :nowait)
    end
  end
end