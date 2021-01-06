require 'sinatra'
require 'linux_stat'
require 'json'
require 'zlib'
require './methods/badger'
require './methods/update'

before {
	headers['Content-Encoding'] = 'deflate'.freeze
}

get '/' do
	content_type 'image/svg+xml'.freeze
	Update.data
	Zlib.deflate(Badger.generate_svg, 9)
end

get '/badge.svg' do
	content_type 'image/svg+xml'.freeze
	Update.data
	Zlib.deflate(Badger.generate_svg, 9)
end

get '/json' do
	Update.data
	content_type :json
	Zlib.deflate(Badger.get_json.to_json, 9)
end

get '/stats' do
	content_type :json
	Zlib.deflate(Badger::stats.to_json, 9)
end

not_found do
	content_type 'text/html'
	html = <<~EOF.lines.each(&:strip!).join(?\n.freeze)
		<!Doctype HTML><html>
		<head><meta charset="utf-8"><title>404</title></head><body>
		#{request.url} is not a valid URL!<br><br>Valid URLs are:<br>
		<a href="#{request.base_url}/">/</a><br>
		<a href="#{request.base_url}/badge.svg">/badge.svg</a><br>
		<a href="#{request.base_url}/stats">/stats</a><br>
		<a href="#{request.base_url}/json">/json</a><br></body></html>
	EOF

	Zlib.deflate(html, 9)
end
