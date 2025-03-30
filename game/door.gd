extends Area2D

func _ready():
	connect("body_entered", _on_body_entered)


func _process(delta):
	var is_unlocked = Global.is_level_complete()
	modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.5, 0.5, 0.5, 1)

func _on_body_entered(body):
	# Check if it's the player (either classic character or tarzan)
	if body.is_in_group("player"):
		if Global.is_level_complete():
			
			Global.level_changed = true
			Global.coins_collected = 0
			print(get_tree().current_scene.name)
			if get_tree().current_scene.name == "level1":
				get_tree().change_scene_to_file("res://level2.tscn")
			elif get_tree().current_scene.name == "level2":
				get_tree().change_scene_to_file("res://level_3.tscn")
		else:
			if body.has_method("show_message"):
				body.show_message("Collect all coins first!")
		
		
