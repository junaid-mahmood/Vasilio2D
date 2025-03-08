extends Control

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_play_button_pressed() -> void:
	# Instead of trying to create tiles which don't exist,
	# just directly change the scene without any tile manipulations
	get_tree().change_scene_to_file("res://main.tscn")
