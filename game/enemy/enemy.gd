extends Area2D

@onready var rayCast2D = $ray_shoot
@export var if_in_radius := 200  # Increased detection range
var player_position = Vector2.ZERO
var health := 100
var can_shoot := true
signal enemy_shoot(pos, player_position)

# Sprite reference
@onready var enemy_sprite = $Sprite2D

func _ready():
	add_to_group("enemies")
	print("Enemy initialized")

func _process(delta: float) -> void:
	if player_position == Vector2.ZERO:
		return
	
	# Face player direction
	var direction_to_player = sign(player_position.x - global_position.x)
	if direction_to_player != 0:
		enemy_sprite.flip_h = direction_to_player < 0
	
	# Shooting logic
	var distance_to_player = global_position.distance_to(player_position)
	if distance_to_player <= if_in_radius:
		update_aim(delta)
		
	if health <= 0:
		queue_free()

func update_aim(delta):
	var dir_to_player = (player_position - global_position).normalized()
	rayCast2D.target_position = dir_to_player * if_in_radius
	rayCast2D.force_raycast_update()
	
	# Shoot if clear path to player
	if !rayCast2D.is_colliding() and can_shoot:
		shoot_at_player(dir_to_player)

func shoot_at_player(direction: Vector2):
	print("Enemy firing!")
	can_shoot = false
	$ShootTimer.start(1.5)  # 1.5 second cooldown
	enemy_shoot.emit(global_position, player_position)

func _on_shoot_timer_timeout():
	can_shoot = true

func _on_character_body_2d_player_pos(pos):
	player_position = pos

func enemy_damage(num):
	print("Enemy taking damage: ", num)
	health -= num
	if health <= 0:
		queue_free()
	# Visual feedback
	var tween = create_tween()
	if has_node("Sprite2D"):
		tween.tween_property(enemy_sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.2)

func _on_area_entered(area: Area2D):
	if area.has_method("_this_is_bow"):
		enemy_damage(40)
	elif area.has_method("_this_is_bullet"):
		enemy_damage(10)
