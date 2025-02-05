extends ProgressBar

func _ready() -> void:
	
	max_value = 100
	value = 100  

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)  
	add_theme_stylebox_override("background", style_box)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.7, 0, 0, 1)  
	add_theme_stylebox_override("fill", fill_style)

	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5

	fill_style.border_width_left = 2
	fill_style.border_width_top = 2
	fill_style.border_width_right = 2
	fill_style.border_width_bottom = 2
	fill_style.border_color = Color(0.7, 0, 0, 0.5)  
