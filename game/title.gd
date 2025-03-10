extends Control


func _on_play_button_pressed() -> void:
	# Instead of trying to create tiles which don't exist,
	# just directly change the scene without any tile manipulations
	get_tree().change_scene_to_file("res://choose_character.tscn")
