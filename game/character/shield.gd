extends StaticBody2D

var protecting := false
var POS:int
var DIREC:int
var DISTANCE_FROM_PLAYER := 60



func _process(_delta: float) -> void:
	protecting = Global.has_shield
	if not protecting:
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		$CollisionShape2D.set_deferred("disabled", false)
