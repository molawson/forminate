# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'forminate/version'

Gem::Specification.new do |spec|
  spec.name          = "forminate"
  spec.version       = Forminate::VERSION
  spec.authors       = ["Mo Lawson"]
  spec.email         = ["moklawson@gmail.com"]
  spec.description   = "Form objects for Rails applications"
  spec.summary       = "Create form objects from multiple Active Record and/or ActiveAttr models."
  spec.homepage      = "https://github.com/molawson/forminate"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "active_attr", "~> 0.8"
  spec.add_dependency "activesupport", ">= 3.0.2", "< 4.1"
  spec.add_dependency "client_side_validations", "~> 3.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.11"
end