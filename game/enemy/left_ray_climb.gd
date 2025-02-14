extends RayCast2D

signal left_climb(nope, if_is)

func _process(delta: float) -> void:
	if is_colliding():
		emit_signal("left_climb", 0, true)
	else:
		emit_signal("left_climb", 0, false)
		
