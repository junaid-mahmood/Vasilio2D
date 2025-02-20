extends StaticBody2D

var protecting := false
var POS:int
var DIREC:int
var DISTANCE_FROM_PLAYER := 60




func _on_character_body_2d_has_shield(shield: Variant) -> void:
	protecting = shield
	if not protecting:
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		$CollisionShape2D.set_deferred("disabled", false)


func _on_character_body_2d_pla_pos_shield(new_pos):
	position = new_pos
	
