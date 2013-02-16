# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ggem/version"

Gem::Specification.new do |gem|
  gem.name        = "ggem"
  gem.version     = GGem::VERSION
  gem.authors     = ["Kelly Redding"]
  gem.email       = ["kelly@kellyredding.com"]
  gem.description = %q{"Juh Gem", baby!  (this makes gems)}
  gem.summary     = %q{"Juh Gem", baby!  (this makes gems)}
  gem.homepage    = "http://github.com/kellyredding/ggem"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert")

end
