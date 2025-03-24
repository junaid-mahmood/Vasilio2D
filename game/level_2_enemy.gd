extends Area2D

@onready var rayCast2D = $ray_shoot
@export var shooting_radius := 200
var player_position
var health := 350
var climbing := false
var climb_l := true
var climb_r := true
var velocity: Vector2 = Vector2.ZERO
var can_shoot := true
var shoot_cooldown := 1.5
var shoot_timer := 0.0

var bullet_pattern := 0
var bullet_count := 0
var shot_delay := 0.0
var shooting_sequence := false

var phase := 1
var strafe_direction := 1
var strafe_speed := 0
var dash_cooldown := true
var can_dash := true
var dash_timer := 0.0
var dash_speed := 600
var can_teleport := true
var teleport_timer := 0.0
var teleport_cooldown := 7.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	player_position = Global.player_position
	
	if climb_l == false or climb_r == false:
		climbing = true
	else:
		climbing = false
	
	check_phase_transition()
	
	handle_movement(delta)
	
	handle_shooting(delta)
	
	position += velocity * delta
	
	if health <= 0:
		handle_death()

func handle_movement(delta: float) -> void:
	var dir_to_player = global_position.direction_to(player_position)
	var distance_to_player = global_position.distance_to(player_position)
	
	if climbing:
		velocity.y -= 500 * delta * 10
	else:
		velocity.y = 0
	
	if phase >= 2:
		velocity.x = strafe_direction * strafe_speed
		if randf() < 0.02:
			strafe_direction *= -1
	
	if not dash_cooldown:
		dash_timer += delta
		if dash_timer >= 2.5:
			dash_cooldown = true
			dash_timer = 0.0
	
	if can_dash and distance_to_player < 180 and dash_cooldown and phase >= 1:
		perform_dash(dir_to_player)
	
	if not can_teleport:
		teleport_timer += delta
		if teleport_timer >= teleport_cooldown:
			can_teleport = true
			teleport_timer = 0.0
	
	if can_teleport and distance_to_player > 250 and phase >= 3:
		perform_teleport()

func handle_shooting(delta: float) -> void:
	if not can_shoot:
		shoot_timer += delta
		if shoot_timer >= shoot_cooldown:
			can_shoot = true
			shoot_timer = 0.0
	
	if shooting_sequence:
		shot_delay -= delta
		if shot_delay <= 0:
			fire_next_bullet()
	
	if can_shoot:
		fire_bullet_pattern()
		can_shoot = false

func fire_next_bullet() -> void:
	var target = Vector2(player_position.x, player_position.y)
	target.y -= 12
	
	if bullet_pattern == 1:
		if bullet_count == 0:
			target.x -= 25
		elif bullet_count == 1:
			target.x = player_position.x
		else:
			target.x += 25
	elif bullet_pattern == 3 and phase >= 3:
		var angle_increment = 45
		var start_angle = 0
		var current_angle = start_angle + (bullet_count * angle_increment)
		var direction = Vector2(cos(deg_to_rad(current_angle)), sin(deg_to_rad(current_angle)))
		target = position + direction * 100
	
	Global.enemy_shoot = [true, position, target]
	bullet_count += 1
	
	if bullet_pattern == 1 and bullet_count >= 3:
		shooting_sequence = false
	elif bullet_pattern == 2 and bullet_count >= phase:
		shooting_sequence = false
	elif bullet_pattern == 3 and bullet_count >= 8:
		shooting_sequence = false
	else:
		var delay_multiplier = 1.0
		if phase == 2:
			delay_multiplier = 0.8
		elif phase == 3:
			delay_multiplier = 0.6
		elif phase == 4:
			delay_multiplier = 0.4
		
		if bullet_pattern == 3:
			shot_delay = 0.1 * delay_multiplier
		else:
			shot_delay = 0.2 * delay_multiplier

func fire_bullet_pattern() -> void:
	if phase >= 3:
		bullet_pattern = (bullet_pattern + 1) % 4
	else:
		bullet_pattern = (bullet_pattern + 1) % 3
	
	if bullet_pattern == 0:
		var target = Vector2(player_position.x, player_position.y)
		target.y -= 12
		Global.enemy_shoot = [true, position, target]
	elif bullet_pattern == 1:
		bullet_count = 0
		shot_delay = 0.0
		shooting_sequence = true
		
		var target = Vector2(player_position.x, player_position.y)
		target.y -= 12
		target.x -= 25
		Global.enemy_shoot = [true, position, target]
	elif bullet_pattern == 2:
		bullet_count = 0
		shot_delay = 0.0
		shooting_sequence = true
		
		var target = Vector2(player_position.x, player_position.y)
		target.y -= 12
		Global.enemy_shoot = [true, position, target]
	elif bullet_pattern == 3:
		bullet_count = 0
		shot_delay = 0.0
		shooting_sequence = true
		
		var angle = 0
		var direction = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))
		var target = position + direction * 100
		Global.enemy_shoot = [true, position, target]

func check_phase_transition() -> void:
	var previous_phase = phase
	
	if health <= 250 and phase == 1:
		phase = 2
		strafe_speed = 180
		shoot_cooldown = 1.2
	
	if health <= 150 and phase == 2:
		phase = 3
		strafe_speed = 220
		shoot_cooldown = 0.9
		shooting_radius = 300
	
	if health <= 80 and phase == 3:
		phase = 4
		strafe_speed = 280
		shoot_cooldown = 0.7
		dash_speed = 750
	
	if previous_phase != phase:
		var tween = create_tween()
		tween.tween_property($Lv2Enemy, "modulate", Color(2.0, 0.5, 0.5, 1), 0.3)
		tween.tween_property($Lv2Enemy, "modulate", Color(1, 1, 1, 1), 0.3)

func perform_dash(direction: Vector2) -> void:
	can_dash = false
	dash_cooldown = false
	
	var dash_dir = direction.normalized()
	velocity = dash_dir * dash_speed
	
	var tween = create_tween()
	tween.tween_property($Lv2Enemy, "modulate", Color(1.5, 0.3, 0.3, 1), 0.2)
	tween.tween_property($Lv2Enemy, "modulate", Color(1, 1, 1, 1), 0.2)
	
	get_tree().create_timer(0.4).timeout.connect(func():
		velocity = Vector2.ZERO
		can_dash = true
	)

func perform_teleport() -> void:
	can_teleport = false
	teleport_timer = 0.0
	
	var teleport_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	var target_pos = player_position + teleport_offset
	
	var tween = create_tween()
	tween.tween_property($Lv2Enemy, "modulate", Color(0.2, 0.2, 1.5, 0.5), 0.2)
	tween.tween_property(self, "position", target_pos, 0.05)
	tween.tween_property($Lv2Enemy, "modulate", Color(1, 1, 1, 1), 0.2)

func handle_death() -> void:
	var tween = create_tween()
	tween.tween_property($Lv2Enemy, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
	tween.tween_property($Lv2Enemy, "modulate", Color(1.5, 0.3, 0.3, 0.8), 0.1)
	tween.tween_property($Lv2Enemy, "modulate", Color(1.5, 1.5, 1.5, 0.6), 0.1)
	tween.tween_property($Lv2Enemy, "modulate", Color(1.5, 0.3, 0.3, 0.4), 0.1)
	tween.tween_property($Lv2Enemy, "modulate", Color(1.5, 1.5, 1.5, 0.2), 0.1)
	tween.tween_property($Lv2Enemy, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_callback(queue_free)

func enemy_damage(num):
	health -= num
	var tween = create_tween()
	tween.tween_property($Lv2Enemy, "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($Lv2Enemy, "material:shader_parameter/amount", 0.0, 0.1)
	
	if phase >= 3 and randf() < 0.3 and can_teleport:
		perform_teleport()

func on_left_ray_climb_left_climb(nope: Variant) -> void:
	climb_l = nope

func on_right_ray_climb_right_climb(nope2: Variant) -> void:
	climb_r = nope2

func on_area_entered(area: Area2D) -> void:
	if area.has_method("_this_is_bow"):
		enemy_damage(25)
	elif area.has_method("_this_is_bullet"):
		enemy_damage(6)
