extends Area2D

@export var next_level: String = "res://level_3.gd"

func _ready():
	connect("body_entered", _on_body_entered)
	print("Door script loaded")

func _process(delta):
	var is_unlocked = Global.is_level_complete()
	modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.5, 0.5, 0.5, 1)

func _on_body_entered(body):
	print("Door body entered by: " + body.name)
	
	if body.name == "CharacterBody2D" or body.name == "tarzan" or body.name == "teleport":
		if Global.is_level_complete():
			print("Player entered door, changing to next level")
			
			Global.level_changed = true
			Global.coins_collected = 0
			
			get_tree().change_scene_to_file(next_level)
		else:
			print("Player entered door, but not all coins collected yet")
			if body.has_method("show_message"):
				body.show_message("Collect all coins first!")
