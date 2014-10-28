require "rspec"
require "support/simplecov"
require "gofer"

require "gofer/rspec/stdio"
require "gofer/rspec/helpers"
require "gofer/rspec/tmp"
require "support/shared"

RSpec.configure do |config|
  config.include Gofer::Rspec::Helpers
end
