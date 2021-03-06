ROOT_DIR = File.expand_path(File.dirname(__FILE__)) unless defined? ROOT_DIR

require "rubygems"

begin
  require File.expand_path("vendor/dependencies/lib/dependencies", File.dirname(__FILE__))
rescue LoadError
  require "dependencies"
end

require "monk/glue"
require "ohm"
require "haml"
require "sass"
require "rack/ssl"
require "url"

class Main < Monk::Glue
  set :app_file, __FILE__
  use Rack::Session::Cookie
  use Rack::SSL unless %w( development ).include?(RACK_ENV)
end

# Pulls settings from ENV first, then settings.yml
def settings(key)
  ENV[key.to_s.upcase] || monk_settings(key)
end

# Connect to redis database.
Ohm.connect(url: settings(:redis_url))

# Load all application files.
Dir[root_path("app/**/*.rb")].each do |file|
  require file
end

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

Main.run! if Main.run?
