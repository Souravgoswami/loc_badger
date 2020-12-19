require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

require 'net/https'
require 'json'

Bundler.require(*Rails.groups)

module LinuxStat
  class Application < Rails::Application
    config.load_defaults 6.1
    config.generators.system_tests = nil
    config.api_only = true
  end
end
