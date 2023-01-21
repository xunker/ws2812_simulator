#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812_simulator'

# Init
n = 64 # num leds
ws = Ws2812::Basic.new(n, 18) # +n+ leds at pin 18, using defaults
ws.open
ws.brightness = 128
if ARGV.first
	puts 'Using direct mode.'
	puts 'Remove all positional parameters to switch to gamma-corrected mode.'
	ws.direct = true
else
	puts 'Using gamma-corrected mode.'
	puts 'Add (any) positional parameter to switch to direct mode.'
end

# up...
0.upto(128) do |i|
	ws[0..63] = Ws2812::Color.new(i, i, i)
	ws.show
	sleep 0.01
end

# and down...
128.downto(0) do |i|
	ws[0..63] = Ws2812::Color.new(i, i, i)
	ws.show
	sleep 0.01
end
