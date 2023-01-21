#!/usr/bin/env ruby
require './ws2812_test'
require 'timers' # #after, #every, #now_and_every

led_string = Ws2812Test.new(count: 1, arrangement: :unicorn_hat)

# puts led_string.leds.first.set_color(r: 1.0)

# led_string.leds.first.events << led_string.timer.after(0.5) {|time, event|
#   puts 'first'
#   led_string.timer.after(0.5) {|time, event|
#     puts led_string.leds.first
#   }
# }

fade_cb = ->(led) {
  adjusted_color = led.get_color(include_alpha: false).map{|color, value|
    if value.to_f > 0.0
      value -= 0.1
      
      # if value <= 0.8
      #   color_key = case led.number % 3
      #   when 0
      #     :r
      #   when 1
      #     :g
      #   when 2
      #     :b
      #   end
      #   led.next_led.set_color(color_key => 1.0)
      # end
      
      # led.next_led.set_color(
      #   r: rand(10).to_f/10,
      #   g: rand(10).to_f/10,
      #   b: rand(10).to_f/10
      # )
    end

    # value = 0.0 if value < 0.0
    [color, value]
  }.to_h

  # if adjusted_color[:r] < 0.0
  #   adjusted_color[:r] = 0.0
  #   adjusted_color[:g] = 1.0
  # elsif adjusted_color[:g] < 0.0
  #   adjusted_color[:g] = 0.0
  #   adjusted_color[:b] = 1.0
  # elsif adjusted_color[:b] < 0.0
  #   adjusted_color[:b] = 0.0
  #   adjusted_color[:r] = 1.0
  # end

  led.set_color(adjusted_color)
}

led_string.leds.each do |led|
  led.every(0.1, &fade_cb)
end

current_led = 0
led_string.timer.every(0.1) do
  if led_string.leds[current_led].nil?
    current_led = 0
    next
  end

  led_string.leds[current_led].set_color(r: 1.0)
  current_led += 1
  if current_led >= led_string.count
    current_led = 0
  end
end

# led_string.leds.first.set_color(r: 1.0)

Thread.new do
  # current_led = 0
  # advance_current_led_timer = led_string.timer.every(0.2) {
  #   current_led += 1
  #   current_led = 0 if current_led > led_string.count-1
    
  #   led_string.leds[current_led].data = {
  #     colors: { r: 1.0, g: 0, b: 0, a: 1.0 },
  #     change: -0.075
  #   }
    
  #   led_string.leds[current_led].set_color(led_string.leds[current_led].data[:colors])  
  # }

  # fade_pixel_timer = led_string.timer.every(0.1) {
  #   led_string.leds.each_with_index do |led, idx|
    
  #     if led.data.length > 0
  #       if led.data[:colors][:r] > 0.0

  #         led.data[:colors][:r] += led.data[:change]
          
  #         if led.data[:colors][:r] < 0
  #           led.data[:colors][:r] = 0
  #         end
            
  #         led.set_color(led.data[:colors])  
  #       end
  #     end
  #   end
  # }

  loop { led_string.timer_wait }
end

# show_thread = Thread.new do
#   loop do
#     11.times do |idx|
#       led_string.leds[idx].set_color(r: 1.0)  
#       sleep(0.5)
#       led_string.leds[idx].set_color(r: 0.0)
#       sleep(0.5)
#     end
    
#   end
# end

th = Thread.new do
  while led_string.count < 11
    sleep 2
    led_string.set_count(led_string.count+1)
    puts led_string.count
    led_string.leds.each do |led|
      led.every(0.1, &fade_cb)
    end
  end
end
led_string.show
