# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qunit/runner/version'

Gem::Specification.new do |spec|
  spec.name          = "qunit-runner"
  spec.version       = Qunit::Runner::VERSION
  spec.authors       = ["M Smart, theScore Inc."]
  spec.email         = ["matthew.smart@thescore.com"]
  spec.description   = %q{QUnit test runner utizing phantomjs in ruby}
  spec.summary       = %q{QUnit test runner utizing phantomjs in ruby}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_runtime_dependency "colorize"
  spec.add_runtime_dependency "thor"
end
