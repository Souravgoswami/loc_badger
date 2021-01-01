Rails.application.routes.draw do
	get "json", to: "index#json"
	get "system_stats", to: "index#stats"
	get "stats", to: "index#stats"
	get "badge.svg", to: "index#generate_badge", as: :badges_path
	root to: "index#generate_badge"
end
