extends Area2D

@onready var rayCast2D = $ray_shoot
@export var if_in_radius := 80
# Instead of preloading a scene, get the actual node instance
var player_position

var can_shoot := true
signal enemy_shoot(pos, player_position)

func _process(delta: float) -> void:
	var dir_to_player = global_position.direction_to(player_position)
	rayCast2D.target_position = dir_to_player * 80
	rayCast2D.force_raycast_update()
	var collision_object = rayCast2D.get_collider()
	print(collision_object)
	if collision_object == null and can_shoot:
		enemy_shoot.emit(position, player_position)
		can_shoot = false
		$shoot.start()

func _on_shoot_timeout() -> void:
	can_shoot = true


func _on_character_body_2d_player_pos(pos: Variant) -> void:
	player_position = pos



	
