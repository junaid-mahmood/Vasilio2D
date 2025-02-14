extends Control

@onready var label = $Label



func _on_character_body_2d_new_coin(coins):
	label.text = str(coins)
