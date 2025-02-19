extends Area2D

var protecting := false


func _process(_delta):
	print(protecting)

func _on_character_body_2d_has_shield(shield: Variant) -> void:
	protecting = shield


func _on_body_entered(body: Node2D) -> void:
	if protecting:
		body.queue_free()


func _on_area_entered(area: Area2D) -> void:
	print('entered')
