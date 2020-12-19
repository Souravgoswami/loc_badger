require 'net/https'
require 'json'

class IndexController < ApplicationController
	WAIT = 300
	GRADIENTS = [
		%w(#3eb #55f),
		%w(#f55 #55f),
		%w(#55f #f5a),
		%w(#f55 #55f #3eb),
		%w(#fa0 #f55 #55f #3eb),
	]

	@@time = Time.now
	@@data = ''.freeze

	def get_json
		if Time.now - @@time > WAIT || @@data.empty?
			@@data = begin
				# test data
				# <<~EOF
				# 	[{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"linesOfCode":1371},{"language":"Markdown","files":1,"lines":1271,"blanks":331,"comments":0,"linesOfCode":940},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"linesOfCode":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"linesOfCode":17},{"language":"Total","files":25,"lines":4357,"blanks":707,"comments":1161,"linesOfCode":2489}]
				# EOF
				# <<~EOF
				# 	[{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"linesOfCode":1371},{"language":"Markdown","files":1,"lines":1277,"blanks":334,"comments":0,"linesOfCode":943},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"linesOfCode":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"linesOfCode":17},{"language":"Total","files":25,"lines":4363,"blanks":710,"comments":1161,"linesOfCode":2492},{"language":"Ruby","files":20,"lines":2862,"blanks":330,"comments":1161,"linesOfCode":1371},{"language":"Markdown","files":1,"lines":1277,"blanks":334,"comments":0,"linesOfCode":943},{"language":"C","files":3,"lines":203,"blanks":42,"comments":0,"linesOfCode":161},{"language":"Plain Text","files":1,"lines":21,"blanks":4,"comments":0,"linesOfCode":17},{"language":"Total","files":25,"lines":4363,"blanks":710,"comments":1161,"linesOfCode":2492}]
				# EOF

				Net::HTTP.get(URI("https://api.codetabs.com/v1/loc/?github=souravgoswami/linux_stat"))
			rescue Exception
				''.freeze
			end

			@@time = Time.now
		end

		json = JSON.parse(@@data).tap(&:uniq!) rescue []

		json <<([{
			"Last Updated": @@time,
			"Updated": "#{Time.now - @@time} s ago",
			"Wait Time": "#{WAIT.-(Time.now - @@time)} s"
		}])
	end

	def json
		render json: get_json
	end

	def generate_badge
		@json_data = get_json
		@stat = @json_data[0..-2]

		@total = @stat.find { |x| x['language'].downcase == 'total' }
		@total_loc = @total['linesOfCode'].to_i

		# Gradient colour
		grad = GRADIENTS.sample
		grad.reverse! if rand < 0.5
		len = 100.fdiv(grad.size.-(1))

		direction = rand < 0.5
		gradient_direction = if rand < 0.5
			%Q(x1="0%" y1="0%" x2="100%" y2="0%")
		else
			%Q(x1="0%" y1="0%" x2="0%" y2="100%")
		end

		gradients = grad.map.with_index { |x, i|
			<<~EOF.freeze
				<stop offset="#{len.*(i).round.clamp(0, 100)}%" stop-color="#{x}"/>)
			EOF
		}.join

		html = @stat.map.with_index do |x, i|
			y = i.+(1) * 18

			<<~EOF
				<text style="filter:url(#shadow) ; line-height:1.25" x="38.2" y="56.1" font-size="10.6" font-family="arial" stroke-width=".3">
					<tspan x="20" y="#{y}" fill="#fff">#{x['language']}: </tspan>
					<tspan x="94" y="#{y}" fill="#fff">
						Lines #{x['linesOfCode']} (#{sprintf "%.2f", x['linesOfCode'].to_i.*(100).fdiv(@total_loc)}%)
					</tspan>
				</text>
				<g transform="translate(3, #{y - 10})" style="filter:url(#shadow)">#{svg_tag(x['language'].strip.split.join.downcase)}</g>
			EOF
		end.join(?\n.freeze)

		size = @stat.size

		html.prepend <<~EOF.freeze
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 210 #{size * 20}">
			<defs>
				<linearGradient id="gradient" #{gradient_direction}>#{gradients}</linearGradient>
				<filter id="shadow"><feDropShadow dx="1" dy="1" stdDeviation="0.25" flood-color="#0002"/></filter>
			</defs>

			<g transform="translate(0 0)">
			<rect width="100%" height="100%" x="0" ry="3" fill="url(#gradient)" paint-order="stroke fill markers"/>
		EOF

		html.concat('</g></svg>'.freeze)

		render plain: html, content_type: 'image/svg+xml'.freeze
	end

	def svg_tag(file)
		file << '.svg'.freeze unless file.end_with?('.svg'.freeze)
		svg_file = File.join(Rails.root, %w(app assets images), "#{file}".freeze)

		if File.exist?(svg_file)
			IO.read(svg_file).html_safe
		else
			''.freeze
		end
	end
end
