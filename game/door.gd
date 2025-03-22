extends Area2D

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	# Check if it's the player (either classic character or tarzan)
	if body.is_in_group("player"):
		
		
		if get_tree().current_scene.name == "level1":
			get_tree().change_scene_to_file("res://level2.tscn")
		elif get_tree().current_scene.name == "level2":
			get_tree().change_scene_to_file("res://level_3.tscn")
