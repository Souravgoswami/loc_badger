#!/usr/bin/env ruby
require 'net/https'

if ENV['APP_URL']
	Net::HTTP.get_response(URI(ENV['APP_URL']))
end
