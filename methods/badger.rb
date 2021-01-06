module Badger
	class << self
		DATA_FILE ||= 'data.txt'.freeze

		GRADIENTS ||= [
			%w(#3eb #55f),
			%w(#f55 #55f),
			%w(#55f #f5a),
			%w(#f55 #55f #3eb)
		].freeze

		@@badge_requests = 0

		def get_json
			data = if File.readable?(DATA_FILE)
				IO.read(DATA_FILE)
			else
				''
			end

			JSON.parse(data).tap(&:uniq!) rescue []
		end

		def generate_svg
			@json_data = get_json
			@json_data = @json_data

			@total = @json_data.find { |x| x['language'.freeze].downcase == 'total'.freeze }.to_h
			@total_loc = @total['lines'.freeze].to_i

			# Gradient colour
			grad = GRADIENTS.sample
			grad.reverse! if rand < 0.5
			len = 100.fdiv(grad.size.-(1))
			size = @json_data.size
			size = 1 if size == 0

			direction = rand < 0.5
			gradient_direction = rand < 0.5 ? %Q(x1="0%" y1="0%" x2="100%" y2="0%") : %Q(x1="0%" y1="0%" x2="0%" y2="100%")

			gradients = grad.map.with_index { |x, i|
				<<~EOF.freeze
					<stop offset="#{len.*(i).round.clamp(0, 100)}%" stop-color="#{x}"/>
				EOF
			}.join

			svg = <<~EOF
				<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 210 #{size * 20}">
				<defs>
					<linearGradient id="gradient" #{gradient_direction}>#{gradients}</linearGradient>
					<filter id="shadow"><feDropShadow dx="1" dy="1" stdDeviation="0.25" flood-color="#0002"/></filter>
				</defs>
				<g><rect width="100%" height="100%" x="0" ry="3" fill="url(#gradient)" paint-order="stroke fill markers"/>
			EOF

			svg << if @json_data.size > 0
				@json_data.map.with_index do |x, i|
					y = i.+(1) * 18

					<<~EOF
						<text style="filter:url(#shadow);line-height:2.25" x="20" y="#{y}" font-size="10" font-family="arial" fill="#fff">
							#{x['language'.freeze]}:
							<tspan x="94">
								Lines #{x['lines'.freeze]} (#{sprintf "%.2f".freeze, x['lines'.freeze].to_i.*(100).fdiv(@total_loc)}%)
							</tspan>
						</text>
						<g transform="translate(3 #{y - 10})" style="filter:url(#shadow)">#{svg_tag(x['language'].strip.split.join.downcase)}</g>
					EOF
				end.join(?\n.freeze)
			else
				<<~EOF.freeze
					<text style="filter:url(#shadow);line-height:2.25" x="2" y="12" font-size="10" font-family="arial" fill="#fff">
						Data Unavailable!
					</text>
				EOF
			end

			@@badge_requests += 1
			svg.lines.each(&:strip!).join << '</g></svg>'.freeze
		end

		def svg_tag(file)
			file << '.svg'.freeze unless file.end_with?('.svg'.freeze)
			svg_file = File.join('assets'.freeze, file)

			if File.readable?(svg_file)
				IO.read(svg_file)
			else
				''.freeze
			end
		end

		def stats
			total_io = LS::ProcessInfo.total_io
			net_usage = LS::Net.total_bytes

			[
				{
					badge_requests: @@badge_requests
				},

				{
					process_cmdline: LS::ProcessInfo.cmdline,
					process_cmdname: LS::ProcessInfo.command_name,
					process_owner: LS::ProcessInfo.owner,
					process_uptime: "#{LS::ProcessInfo.running_time} s",
					process_start_time: LS::ProcessInfo.start_time,
					process_allocated_cpu: LS::ProcessInfo.nproc,
					process_cpu_usage: "#{LS::ProcessInfo.cpu_usage}%",
					process_threads: LS::ProcessInfo.threads,
					process_last_executed_cpu: LS::ProcessInfo.last_executed_cpu,
					process_memory_usage: LS::PrettifyBytes.convert_short_binary(LS::ProcessInfo.memory * 1024),
					process_resident_memory: LS::PrettifyBytes.convert_short_binary(LS::ProcessInfo.resident_memory * 1024),
					process_virtual_memory: LS::PrettifyBytes.convert_short_binary(LS::ProcessInfo.virtual_memory * 1024),
					process_io_read: LS::PrettifyBytes.convert_short_binary(total_io[:read_bytes]),
					process_io_write: LS::PrettifyBytes.convert_short_binary(total_io[:write_bytes]),
					process_state: LS::ProcessInfo.state
				},

				{
					system_distribution: LS::OS.distribution,
					system_distribution_version: LS::OS.version,
					system_version: LS::OS.bits,
					system_nodename: LS::OS.nodename,
					system_hostname: LS::OS.hostname,
					system_uptime: LS::OS.uptime,

					system_total_cpu: LS::CPU.count,
					system_online_cpu: LS::CPU.count_online,
					system_cpu_usage: LS::CPU.usages,

					system_kernel: LS::Kernel.version,
					system_kernel_build_date: LS::Kernel.build_date,
					system_kernel_build_user: LS::Kernel.build_user,

					system_ip: LS::Net.ipv4_private,
					system_net_usage_download: LS::PrettifyBytes.convert_short_binary(net_usage[:received]),
					system_net_usage_upload: LS::PrettifyBytes.convert_short_binary(net_usage[:transmitted]),

					system_total_memory: LS::PrettifyBytes.convert_short_binary(LS::Memory.total * 1024),
					system_used_memory: LS::PrettifyBytes.convert_short_binary(LS::Memory.used * 1024),
					system_available_memory: LS::PrettifyBytes.convert_short_binary(LS::Memory.available * 1024),
					system_total_swap: LS::PrettifyBytes.convert_short_binary(LS::Swap.total * 1024),
					system_used_swap: LS::PrettifyBytes.convert_short_binary(LS::Swap.used * 1024),
					system_available_swap: LS::PrettifyBytes.convert_short_binary(LS::Swap.available * 1024),
					system_total_disk: LS::PrettifyBytes.convert_short_binary(LS::Filesystem.total),
					system_used_disk: LS::PrettifyBytes.convert_short_binary(LS::Filesystem.used),
					system_free_disk: LS::PrettifyBytes.convert_short_binary(LS::Filesystem.free)
				}
			]
		end
	end
end
