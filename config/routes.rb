Rails.application.routes.draw do
	root to: "index#json"
	get "badge.svg", to: "index#generate_badge", as: :badges_path
end
