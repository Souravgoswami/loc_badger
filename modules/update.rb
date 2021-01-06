# Frozen_String_Literal: true
require 'net/https'
require 'json'

module Update
	class << self
		DATA_FILE = 'data.txt'.freeze
		DATA_UPDATE_INTERVAL = 900
		@@update_time ||= Time.now  - DATA_UPDATE_INTERVAL

		def data
			if Time.now - @@update_time > DATA_UPDATE_INTERVAL
				@@update_time = Time.now

				Thread.new {
					retry_count = 0

					begin
						data = Net::HTTP.get(URI("https://api.codetabs.com/v1/loc/?github=souravgoswami/linux_stat".freeze))
						data_minified = data.lines.map!(&:strip).join

						# Check if it's a vaild JSON data
						JSON.parse!(data_minified, max_nesting: 3)
						IO.write(DATA_FILE, data_minified)
					rescue Exception
						sleep 5
						puts "Caught Exception: #{$!}"
						retry_count += 1

						retry if retry_count < 3
					end
				}
			end
		end
	end
end
