# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cenit/collection/base'

Gem::Specification.new do |spec|
  spec.name          = %q{cenit-collection-base}
  spec.version       = Cenit::Collection::Base::VERSION
  spec.authors       = ["asnioby"]
  spec.email         = ["asnioby@gmail.com"]

  spec.summary       = %q{Cenit collection build class}
  spec.description   = %q{Base code to build Cenit Collection}
  spec.homepage      = "https://github.com/openjaf/cenit-collection-base"
  spec.license       = %q{MIT}

  spec.rubyforge_project = "cenit-collection"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
