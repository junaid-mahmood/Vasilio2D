extends Control

@onready var label = $Label



func _process(delta: float) -> void:
	var coins = Global.coins_collected
	label.text = str(coins)
	if coins == 13:
		print("game won!")
		get_tree().reload_current_scene()
