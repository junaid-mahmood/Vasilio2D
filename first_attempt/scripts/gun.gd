extends Area2D


func _process(delta):
	position.y += sin(Time.get_ticks_msec() / 200) * delta * 20


func _on_body_entered(body: Node2D) -> void:
	if "has_gun" in body:
		body.has_gun = true
		queue_free()
