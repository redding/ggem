# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ggem/version"

Gem::Specification.new do |s|
  s.name        = "ggem"
  s.version     = GGem::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kelly Redding"]
  s.email       = ["kelly@kelredd.com"]
  s.homepage    = "http://github.com/kelredd/ggem"
  s.summary     = %q{"Juh Gem", baby!  (this makes gems)}
  s.description = %q{Quickly, easily, consistantly generate a ruby gem project ready to build, test, and deploy.  Uses Bundler's gem building features.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("bundler")
  s.add_development_dependency("assert")
end
