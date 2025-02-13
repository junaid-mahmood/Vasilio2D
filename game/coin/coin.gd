extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if "coin_collected" in body:
		body.coin_collected(1)
		queue_free()
	
