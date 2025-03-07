extends CanvasModulate



func _process(delta: float) -> void:
	if Global.dead:
		visible = true
	else:
		visible = false
