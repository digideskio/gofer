require "rspec"
require "support/simplecov"
require "gofer"

require "gofer/rspec/stdio"
require "gofer/rspec/helpers"
require "support/shared"

RSpec.configure do |config|
  config.include Gofer::Rspec::Helpers
end
