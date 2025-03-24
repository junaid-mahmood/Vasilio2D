extends Area2D

func _ready():
	add_to_group("teleport_trigger")
	monitoring = true
	monitorable = true
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("teleport_to_spawn"):
			body.teleport_to_spawn()
		else:
			body.position = body.spawn_position
