# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simple_gem/version"

Gem::Specification.new do |s|
  s.name        = "kelredd-simple-gem"
  s.version     = SimpleGem::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kelly Redding (and Patrick Reagan)"]
  s.email       = ["kelly@kelredd.com"]
  s.homepage    = "http://github.com/kelredd/simple-gem"
  s.summary     = %q{Quickly generate a new Ruby gem project.}
  s.description = %q{A gem to help quickly generate a ruby gem project ready to build, test, and deploy.  Uses Bundler's gem building features and mixes in helpers for testing.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("bundler", ["~> 1.0"])
  s.add_development_dependency("test-belt", ["= 0.1.2"]) # lock in a specific version for test stability
end
