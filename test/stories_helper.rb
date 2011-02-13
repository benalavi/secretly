require "test_helper"

require "rack/test"
require "capybara/dsl"
require "stories"
require "stories/runner"
require "capybara/server"

Capybara.default_driver = :selenium
Capybara.app = Main

class Capybara::Server
  alias original_boot boot

  def boot
    # Update settings(:host) with the currently running server.
    original_boot.tap { $monk_settings[:host] = url("/")[7..-2] }
  end
end

class Test::Unit::TestCase
  include Webrat::Methods
  include Webrat::Matchers
  include Stories::Webrat
  include Capybara
end
