
extends RayCast2D

signal left_climb(nope)

func _process(delta: float) -> void:
	if is_colliding():
		emit_signal("left_climb", false)
	else:
		emit_signal("left_climb", true)
		
