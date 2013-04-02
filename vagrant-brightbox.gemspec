# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-brightbox/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-brightbox"
  gem.version       = VagrantPlugins::Brightbox::VERSION
  gem.authors       = ["Mitchell Hashimoto", "Neil Wilson"]
  gem.email         = ["neil@aldur.co.uk"]
  gem.description   = "Enables Vagrant to manage servers in Brightbox Cloud."
  gem.summary       = "Enables Vagrant to manage servers in Brightbox Cloud."

  gem.add_runtime_dependency "fog", "~> 1.10.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.13.0"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
