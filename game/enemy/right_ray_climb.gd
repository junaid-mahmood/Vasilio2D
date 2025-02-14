extends RayCast2D


func _process(delta: float) -> void:
	if is_colliding():
		emit_signal("left_climb", 1, true)
	else:
		emit_signal("left_climb", 1, false)
