require "rspec"
require "gofer"

[:helpers, :shared].each { |v| require File.expand_path("../../support/#{v}", __FILE__) }
RSpec.configure do |config|
  config.include IntegrationHelpers
end
