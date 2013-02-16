# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ggem/version"

Gem::Specification.new do |gem|
  gem.name        = "ggem"
  gem.version     = GGem::VERSION
  gem.summary     = %q{"Juh Gem", baby!  (this makes gems)}
  gem.description = %q{"Juh Gem", baby!  (this makes gems)}

  gem.authors     = ["Kelly Redding"]
  gem.email       = ["kelly@kellyredding.com"]
  gem.homepage    = "http://github.com/kellyredding/ggem"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert")
end
