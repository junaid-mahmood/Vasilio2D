extends RigidBody2D

var beggining_pos:Vector2

func _ready() -> void:
	beggining_pos = global_position
	
func _process(delta: float) -> void:
	if beggining_pos.distance_to(global_position) > 1:
		$CollisionShape2D.set_deferred("disabled", true)
		


func timeout_turnoff():
	await get_tree().create_timer(3).timeout
	$CollisionShape2D.set_deferred("disabled", false)
