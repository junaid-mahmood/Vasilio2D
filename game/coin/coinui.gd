extends Control

@onready var label = $Label



func _on_character_body_2d_new_coin(coins):
	label.text = str(coins)
	if coins == 13:
		print("game won!")
		get_tree().reload_current_scene()
