extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	print("Door script loaded")

func _on_body_entered(body):
	print("Something entered: " + body.name)
	if body.name == "CharacterBody2D":
		print("Player detected! Changing to Level 2")
		get_tree().change_scene_to_file("res://Level2.tscn")
