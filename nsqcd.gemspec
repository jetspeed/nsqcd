
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nsqcd/version"

Gem::Specification.new do |spec|
  spec.name          = "nsqcd"
  spec.version       = Nsqcd::VERSION
  spec.authors       = ["jetspeed"]
  spec.email         = ["shmimy-w@163.com"]

  spec.summary       = %q{nsq consumer daemon}
  spec.description   = %q{nsq consumer daemon, using serverengin and nsq_ruby.}
  spec.homepage      = "https://rubygems.org/gems/nsqcd"
  srcpage           = "https://github.com/jetspeed/nsqcd"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = spec.homepage 
    spec.metadata["homepage_uri"] = srcpage
    spec.metadata["source_code_uri"] = srcpage
    spec.metadata["changelog_uri"] = srcpage
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

  spec.add_dependency 'serverengine', '~> 2.1.0'
  spec.add_dependency 'nsq-ruby', '~> 2.3.1'
  spec.add_dependency 'connection_pool', '~> 2.2.2'


  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
