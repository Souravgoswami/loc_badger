class IndexController < ApplicationController
	DATA_FILE = File.join(Rails.root, 'data.txt')
	GRADIENTS = [
		%w(#3eb #55f),
		%w(#f55 #55f),
		%w(#55f #f5a),
		%w(#f55 #55f #3eb)
	]

	def get_json
		@@data = if File.readable?(DATA_FILE)
			IO.read(DATA_FILE)
		else
			''
		end
		# @@data = %Q([{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"linesOfCode":1371},{"language":"Markdown","files":1,"lines":1277,"blanks":334,"comments":0,"linesOfCode":943},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"linesOfCode":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"linesOfCode":17},{"language":"Total","files":25,"lines":4363,"blanks":710,"comments":1161,"linesOfCode":2492},{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"linesOfCode":1371},{"language":"Markdown","files":1,"lines":1277,"blanks":334,"comments":0,"linesOfCode":943},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"linesOfCode":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"linesOfCode":17},{"language":"Total","files":25,"lines":4363,"blanks":710,"comments":1161,"linesOfCode":2492}])

		JSON.parse(@@data).tap(&:uniq!) rescue []
	end

	def json
		render json: get_json
	end

	def generate_badge
		@json_data = get_json
		@json_data = @json_data

		@total = @json_data.find { |x| x['language'].downcase == 'total' }.to_h
		@total_loc = @total['linesOfCode'].to_i

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
							Lines #{x['linesOfCode']} (#{sprintf "%.2f", x['linesOfCode'].to_i.*(100).fdiv(@total_loc)}%)
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

		return_svg = svg.lines.each(&:strip!).join << '</g></svg>'.freeze
		render plain: return_svg, content_type: 'image/svg+xml'.freeze
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
end
