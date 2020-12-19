desc "Pings APP_URL to keep dyno alive"
task :dyno_ping do
	require 'net/https'

	if ENV['APP_URL']
		Net::HTTP.get_response(URI(ENV['APP_URL']))
	end
end
