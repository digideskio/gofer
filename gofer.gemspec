$:.push File.expand_path("../lib", __FILE__)
require "gofer/version"

Gem::Specification.new do |s|
  s.name = "envygeeks-gofer"
  s.version = Gofer::VERSION
  s.authors = ["Jordon Bedwell", "Michael Pearson"]
  s.email = ["jordon@envygeeks.io", "mipearson@gmail.com"]
  s.homepage = "https://github.com/envygeeks/gofer"
  s.summary = %q{run commands on remote servers using SSH}
  s.description = %q{Gofer provides a flexible and reliable model for performing tasks on remote server using Net::SSH}
  s.files = %W(Rakefile Gemfile LICENSE README.md) + Dir["lib/**/*"]
  s.require_paths = ["lib"]
  s.license = "MIT"

  s.add_development_dependency("rspec", "~> 3.3")
  s.add_development_dependency("rspec-mocks", "~> 3.3")
  s.add_development_dependency("envygeeks-coveralls", "~> 1.0")
  s.add_dependency("net-ssh", "~> 3.0")
  s.add_dependency("net-scp", "~> 1.2")
end
