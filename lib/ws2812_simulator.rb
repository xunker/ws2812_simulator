# require 'socket'
require 'simple-fifo'
require 'io/wait' # for .ready? call on IO obj

require "ws2812_simulator/version"
require "ws2812_simulator/display"
require "ws2812_simulator/basic"
require "ws2812_simulator/color"
require "ws2812_simulator/unicorn_hat"


module Ws2812Simulator
  class Error < StandardError; end
  # Your code goes here...
end
