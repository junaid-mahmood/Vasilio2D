extends Area2D

func _ready():
	# Ensure the sword has a proper collision shape
	if not has_node("CollisionShape2D"):
		print("ERROR: Sword lacks a collision shape")

func _this_is_sword():
	return true 