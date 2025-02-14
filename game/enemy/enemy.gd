extends Area2D

@onready var rayCast2D = $ray_shoot
@export var if_in_radius := 80
# Instead of preloading a scene, get the actual node instance
var player_position
var health := 100

var climbing := false


var can_shoot := true
signal enemy_shoot(pos, player_position)

func _process(delta: float) -> void:
	var dir_to_player = global_position.direction_to(player_position)
	rayCast2D.target_position = dir_to_player * 80
	rayCast2D.force_raycast_update()
	var collision_object = rayCast2D.get_collider()
	if collision_object == null and can_shoot:
		enemy_shoot.emit(position, player_position)
		can_shoot = false
		$shoot.start()
	if health <= 0:
		queue_free()
		


func _on_shoot_timeout() -> void:
	can_shoot = true


func _on_character_body_2d_player_pos(pos: Variant) -> void:
	player_position = pos


func enemy_damage(num):
	health -= num
	var tween = create_tween()
	tween.tween_property($"Jump(32x32)", "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($"Jump(32x32)", "material:shader_parameter/amount", 0.0, 0.1)


func _on_area_entered(area: Area2D) -> void:
	enemy_damage(40)



func _on_left_ray_climb_left_climb(nope: Variant, if_is: Variant) -> void:
	var if_is_climbing = {
		0: true,
		1: true
	}
	if_is = int(if_is)

	if if_is == 0 or if_is == 1:
		if_is_climbing[if_is] = nope
	
	var climbing = false
	for value in if_is_climbing.values():
		if value:
			climbing = true
			break
	print(if_is_climbing)
	
	
