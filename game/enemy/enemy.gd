extends Area2D

@onready var rayCast2D = $ray_shoot
@onready var sprite = $"Jump(32x32)"
@export var if_in_radius := 40
var player_position: Vector2
var health := 100
var climbing := false
var climb_l := true
var climb_r := true
var velocity: Vector2 = Vector2.ZERO
var can_shoot := true
var is_hurt := false
var is_dying := false
var is_attacking := false
signal enemy_shoot(pos, player_position)

func _ready() -> void:
	sprite.connect("animation_finished", _on_animation_finished)

func _process(delta: float) -> void:
	if is_dying:
		return
		
	if health <= 0 and not is_dying:
		die()
		return
		
	if is_attacking or is_hurt:
		return
		
	if climb_l == false or climb_r == false:
		climbing = true
	else:
		climbing = false
	
	if player_position:
		var dir_to_player = global_position.direction_to(player_position)
		rayCast2D.target_position = dir_to_player * 80
		rayCast2D.force_raycast_update()
		var collision_object = rayCast2D.get_collider()
		
		if collision_object == null and can_shoot and not is_attacking:
			attack()
		
		sprite.flip_h = player_position.x < global_position.x
		
	if climbing:
		velocity.y -= 500 * delta * 10
		sprite.handle_run()
	else:
		velocity.y = 0
		if not is_hurt and not is_attacking and health > 0:
			sprite.handle_idle()
		
	position += velocity * delta

func attack():
	if not is_attacking and can_shoot:
		is_attacking = true
		can_shoot = false
		player_position.y -= 12
		enemy_shoot.emit(position, player_position)
		sprite.handle_attack()
		$shoot.start()

func die():
	if not is_dying:
		is_dying = true
		sprite.handle_death()
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

func _on_animation_finished():
	if sprite.animation == "death":
		queue_free()
	elif sprite.animation == "hurt":
		is_hurt = false
		if health > 0:
			sprite.handle_idle()
	elif sprite.animation == "attack":
		is_attacking = false
		if health > 0 and not is_dying:
			sprite.handle_idle()

func _on_shoot_timeout() -> void:
	can_shoot = true

func _on_character_body_2d_player_pos(pos: Variant) -> void:
	player_position = pos

func enemy_damage(num):
	if is_dying or health <= 0:
		return
		
	health -= num
	print("Enemy health: ", health)
	
	if health <= 0:
		health = 0
		die()
		return
		
	is_hurt = true
	is_attacking = false
	sprite.handle_hurt()
	
	var tween = create_tween()
	tween.tween_property($"Jump(32x32)", "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($"Jump(32x32)", "material:shader_parameter/amount", 0.0, 0.1)

func _on_left_ray_climb_left_climb(nope: Variant) -> void:
	climb_l = nope

func _on_right_ray_climb_right_climb(nope2: Variant) -> void:
	climb_r = nope2

func _on_area_entered(area: Area2D) -> void:
	if is_dying:
		return
		
	if area.has_method("_this_is_bow"):
		enemy_damage(40)
	elif area.has_method("_this_is_bullet"):
		enemy_damage(10)
