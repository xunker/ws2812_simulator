
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ws2812_simulator/version"

Gem::Specification.new do |spec|
  spec.name          = "ws2812_simulator"
  spec.version       = Ws2812Simulator::VERSION
  spec.authors       = ["Matthew Nielsen"]
  spec.email         = ["xunker@pyxidis.org"]

  spec.summary       = %q{Simulate WS2812 LEDs on a computer that is not a Raspberry Pi}
  spec.description   = %q{A drop-in replacement for the Ws2812 gem that allows you to develop for WS2812 LEDs without having to write/run your code on the raspberry pi. Once you are finished, swap this gem for the original Ws2812 gem and run with real hardware.}
  spec.homepage      = "https://github.com/xunker/ws2812_simulator"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/xunker/ws2812_simulator"
    spec.metadata["changelog_uri"] = "https://github.com/xunker/ws2812_simulator/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ruby2d'
  spec.add_dependency 'jimson'
  spec.add_dependency 'rack', '~>2.2.7' # jimson has problem with 3.x.x

  # spec.add_development_dependency "rake", "~> 10.0"
  # spec.add_development_dependency "rspec", "~> 3.0"
end
