desc "Updates data from codetabs"
task :update_data do
	require 'net/https'
	require 'json'

	data_file = File.join(Rails.root, 'data.txt'.freeze).freeze

	begin
		data = Net::HTTP.get(URI("https://api.codetabs.com/v1/loc/?github=souravgoswami/linux_stat".freeze))
		data_minified = data.lines.map!(&:strip).join

		# Check if it's a vaild JSON data
		JSON.parse!(data_minified, max_nexting: 3)
		IO.write(data_file, data_minified)
	rescue Exception
		sleep 1
		puts "Caught Exception: #{$!}"
		retry
	end
end
