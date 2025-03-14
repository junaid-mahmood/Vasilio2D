extends Area2D

func _ready():
	connect("body_entered", _on_body_entered)
	print("Door script loaded")

func _on_body_entered(body):
	print("Door body entered by: " + body.name)
	
	# Check if it's the player (either classic character or tarzan)
	if body.name == "CharacterBody2D" or body.name == "tarzan":
		print("Player entered door, changing to level2")
		get_tree().change_scene_to_file("res://level2.tscn")
