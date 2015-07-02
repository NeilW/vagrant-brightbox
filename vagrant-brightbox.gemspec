# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-brightbox/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-brightbox"
  gem.version       = VagrantPlugins::Brightbox::VERSION
  gem.platform      = Gem::Platform::RUBY
  gem.license       = "MIT"
  gem.authors       = ["Mitchell Hashimoto", "Neil Wilson"]
  gem.email         = ["neil@aldur.co.uk"]
  gem.description   = "Enables Vagrant to manage servers in Brightbox Cloud."
  gem.summary       = "Enables Vagrant to manage servers in Brightbox Cloud."

  gem.required_ruby_version = ">= 2.0.0"
  gem.required_rubygems_version = ">= 1.3.6"

  gem.add_runtime_dependency "fog-brightbox", "~> 0.7"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.13.0"

  # The following block of code determines the files that should be included
  # in the gem. It does this by reading all the files in the directory where
  # this gemspec is, and parsing out the ignored files from the gitignore.
  # Note that the entire gitignore(5) syntax is not supported, specifically
  # the "!" syntax, but it should mostly work correctly.
  root_path      = File.dirname(__FILE__)
  all_files      = Dir.chdir(root_path) { Dir.glob("**/{*,.*}") }
  all_files.reject! { |file| [".", ".."].include?(File.basename(file)) }
  gitignore_path = File.join(root_path, ".gitignore")
  gitignore      = File.readlines(gitignore_path)
  gitignore.map!    { |line| line.chomp.strip }
  gitignore.reject! { |line| line.empty? || line =~ /^(#|!)/ }

  unignored_files = all_files.reject do |file|
    # Ignore any directories, the gemspec only cares about files
    next true if File.directory?(file)

    # Ignore any paths that match anything in the gitignore. We do
    # two tests here:
    #
    #   - First, test to see if the entire path matches the gitignore.
    #   - Second, match if the basename does, this makes it so that things
    #     like '.DS_Store' will match sub-directories too (same behavior
    #     as git).
    #
    gitignore.any? do |ignore|
      File.fnmatch(ignore, file, File::FNM_PATHNAME) ||
        File.fnmatch(ignore, File.basename(file), File::FNM_PATHNAME)
    end
  end

  gem.files         = unignored_files
  gem.executables   = unignored_files.map { |f| f[/^bin\/(.*)/, 1] }.compact
  gem.require_path  = 'lib'

end
