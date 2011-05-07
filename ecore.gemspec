# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ecore/version"

Gem::Specification.new do |s|
  s.name        = "ecore"
  s.version     = Ecore::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["thorsten zerha"]
  s.email       = ["thorsten.zerha@tastenwerk.com"]
  s.homepage    = ""
  s.summary     = %q{ecore is a environmental friendly content repository. It just takes little resources but implements a fully content repository in ruby}
  s.description = %q{environmental-friendly content repository written in ruby}

  s.rubyforge_project = "ecore"

  s.files           = `git ls-files`.split("\n")
  s.test_files      = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables     = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths   = ["lib"]
  
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options     = ["--main", "README.rdoc"]

  s.add_development_dependency "rspec"

  s.add_dependency "nokogiri" #, "1.5.0.beta.4"
  s.add_dependency "activemodel"
  s.add_dependency "activesupport"
  
end
