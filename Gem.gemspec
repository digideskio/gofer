# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gofer/version"

Gem::Specification.new do |s|
  s.name = "envygeeks-gofer"
  s.version = Gofer::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jordon Bedwell", "Michael Pearson"]
  s.email = ["jordon@envygeeks.io", "mipearson@gmail.com"]
  s.homepage = "https://github.com/envygeeks/gofer"
  s.summary = %q{run commands on remote servers using SSH}
  s.description = %q{Gofer provides a flexible and reliable model for performing tasks on remote server using Net::SSH}
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency("rspec", "~> 3.1")
  s.add_development_dependency("rspec-mocks", "~> 3.1")
  s.add_dependency("net-ssh", "~> 2.9")
  s.add_dependency("net-scp", ">= 1.2")
end
