extends Control

@onready var label = $Label



func _process(delta: float) -> void:
	var coins = Global.coins_collected
	label.text = str(coins)
