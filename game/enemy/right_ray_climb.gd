extends RayCast2D

signal right_climb(nope2)

func _process(_delta: float) -> void:
	if is_colliding():
		emit_signal("right_climb", false)
	else:
		emit_signal("right_climb", true)
