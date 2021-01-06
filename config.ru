require './app'

run Sinatra::Application

# run proc { |x|
# 	[
# 		200,
# 		{'Content-Type' => 'text/plain'},
# 		StringIO.new(generate_svg)
# 	]
# }
