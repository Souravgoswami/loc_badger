class IndexController < ApplicationController
	DATA_FILE = File.join(Rails.root, 'data.txt')
	GRADIENTS = [
		%w(#3eb #55f),
		%w(#f55 #55f),
		%w(#55f #f5a),
		%w(#f55 #55f #3eb)
	]

	DATA_UPDATE_INTERVAL = 900

	@@update_time = Time.now - DATA_UPDATE_INTERVAL

	def get_json
		update_data()

		data = if File.readable?(DATA_FILE)
			IO.read(DATA_FILE)
		else
			''
		end
		# @@data = %Q([{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"lines":1371},{"language":"Markdown","files":1,"lines":1277,"blanks":334,"comments":0,"lines":943},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"lines":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"lines":17},{"language":"Total","files":25,"lines":4363,"blanks":710,"comments":1161,"lines":2492},{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"lines":1371},{"language":"Markdown","files":1,"lines":1277,"blanks":334,"comments":0,"lines":943},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"lines":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"lines":17},{"language":"Total","files":25,"lines":4363,"blanks":710,"comments":1161,"lines":2492}])

		JSON.parse(data).tap(&:uniq!) rescue []
	end

	def json
		response.headers['Content-Encoding'] = 'deflate'
		render plain: Zlib.deflate(JSON.generate(get_json), 9), content_type: 'application/json'
	end

	def generate_badge
		@json_data = get_json
		@json_data = @json_data

		@total = @json_data.find { |x| x['language'].downcase == 'total' }.to_h
		@total_loc = @total['lines'].to_i

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
						#{x['language']}:

						<tspan x="94">
							Lines #{x['lines']} (#{sprintf "%.2f", x['lines'].to_i.*(100).fdiv(@total_loc)}%)
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

		response.headers['Content-Encoding'] = 'deflate'
		return_svg = svg.lines.each(&:strip!).join << '</g></svg>'.freeze

		deflated = Zlib.deflate(return_svg, 9)
		render plain: deflated, content_type: 'image/svg+xml'.freeze
	end

	def svg_tag(file)
		file << '.svg'.freeze unless file.end_with?('.svg'.freeze)
		svg_file = File.join(Rails.root, %w(app assets images), "#{file}".freeze)

		if File.exist?(svg_file)
			IO.read(svg_file)
		else
			''.freeze
		end
	end

	private
	def update_data
		if Time.now - @@update_time > DATA_UPDATE_INTERVAL
			@@update_time = Time.now

			Thread.new {
				begin
					data = Net::HTTP.get(URI("https://api.codetabs.com/v1/loc/?github=souravgoswami/linux_stat".freeze))
					data_minified = data.lines.map!(&:strip).join

					# Check if it's a vaild JSON data
					JSON.parse!(data_minified, max_nexting: 3)
					IO.write(DATA_FILE, data_minified)
				rescue Exception
					sleep 1
					puts "Caught Exception: #{$!}"
					retry
				end
			}
		end
	end
end
