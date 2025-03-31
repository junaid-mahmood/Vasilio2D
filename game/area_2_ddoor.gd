extends Area2D

@export var next_level: String = "res://level_3.tscn"

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	var is_unlocked = Global.is_level_complete()
	modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.5, 0.5, 0.5, 1)

func _on_body_entered(body):
	var is_player = body.is_in_group("player") or body.name == "CharacterBody2D" or body.name == "tarzan" or body.name == "teleport"
	
	if is_player:
		if Global.is_level_complete():
			Global.level_changed = true
			Global.coins_collected = 0
			
			var scene_path = next_level
			if not scene_path.ends_with(".tscn"):
				scene_path = scene_path.replace(".gd", ".tscn")
			
			get_tree().change_scene_to_file(scene_path)
		else:
			if body.has_method("show_message"):
				body.show_message("Collect all coins first!")
