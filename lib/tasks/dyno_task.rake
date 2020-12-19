desc "Pings APP_URL to keep dyno alive"
task :dyno_ping do
	require 'net/https'
	t = Time.now

	if ENV['APP_URL']
		while true
			Net::HTTP.get_response(URI(ENV['APP_URL']))
			sleep 600
		end
	end
end
