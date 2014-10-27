require "rspec"
require "support/simplecov"
require "gofer"

require "support/helpers"
require "support/mock_remote"
require "support/shared"

RSpec.configure do |config|
  config.include IntegrationHelpers
end
