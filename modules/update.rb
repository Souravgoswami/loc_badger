# Frozen_String_Literal: true
require 'net/https'
require 'json'
require'fileutils'

module Update
	class << self
		DATA_FILE = 'data.txt'.freeze
		DATA_UPDATE_INTERVAL = 1800
		@@update_time ||= Time.now  - DATA_UPDATE_INTERVAL
		@@thread = Thread.new { }

		def update!
			FileUtils.rm_rf(File.join(Dir.pwd, 'tmp', 'linux_stat'))

			system("git clone https://github.com/Souravgoswami/linux_stat.git --branch master --single-branch --depth=1 #{File.join(Dir.pwd, 'tmp', 'linux_stat')} &>#{File::NULL}")

			data = IO.popen(
				"#{File.join(Dir.pwd, 'bin', 'cloc')} #{File.join(Dir.pwd, 'tmp', 'linux_stat')} --json"
			).read

			data_minified = data.lines.map!(&:strip).join

			# Check if it's a vaild JSON data
			JSON.parse!(data_minified, max_nesting: 3)
			IO.write(DATA_FILE, data_minified)
			puts "Updated data at: #{Time.now.strftime("%d %b %Y, %H:%M:%S")}"
		end

		def data
			if Time.now - @@update_time > DATA_UPDATE_INTERVAL
				@@update_time = Time.now

				unless @@thread.alive?
					@@thread = Thread.new {
						retry_count = 0

						begin
							update!
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
end
