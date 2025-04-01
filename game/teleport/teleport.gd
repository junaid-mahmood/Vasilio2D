extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 20.0
const PORTAL_COST := 50.0
const ATTACK_COST := 30.0
const DOUBLE_JUMP_COST := 40.0

var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var jumping := false
var coyote := false
var facing_right := false
var coins := 0
var spawn_pos = Vector2.ZERO

var mouse_pos = Vector2.ZERO
var max_portal_distance = 350
@onready var ray_cast = $portal_pos
var current_portal_pos := Vector2.ZERO
var portal1 = Vector2.ZERO
var portal2 = Vector2.ZERO
var can_teleport := true
var can_teleport_timer := true
var teleport_cooldown := 5.0
var portal_lifetime := 15.0
var portal_count := 0
var max_portals_per_level := 4
var portal_timer := 0.0
var damage_number_scene = preload("res://damage_number.tscn")
var portal_scene = preload("res://teleport/portal.tscn")
var weapons = ['teleport', 'melee']

var attack_damage := 40
var attack_radius := 500.0
var attack_cooldown := 0.0
var attack_cooldown_time := 0.5

var quantum_acceleration_active := false
var quantum_acceleration_cooldown := 0.0
var quantum_acceleration_cooldown_time := 5.0
var quantum_acceleration_duration := 3.0
var quantum_acceleration_timer := 0.0
var quantum_acceleration_cost := 50.0
var quantum_particles = []

var speed_multiplier := 1.0
var jump_multiplier := 1.0
var attack_multiplier := 1.0
var portal_range_multiplier := 1.0
var portal_shoot_timeout := false

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	spawn_pos = global_position
	
	collision_layer = 8
	collision_mask = 15
	
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	
	Global.has_shield = false
	Global.player_position = position
	
	
	create_portal_indicator()

func create_portal_indicator():
	var indicator = Line2D.new()
	indicator.name = "PortalIndicator"
	indicator.width = 2.0
	indicator.default_color = Color(0.2, 0.6, 1.0, 0.5)
	indicator.visible = false
	add_child(indicator)

func _process(delta: float) -> void:
	Global.player_position = position
	
	if is_on_floor():
		coyote = true
		jumping = false
	else:
		coyote_change()
		
	if health_bar.value <= 0:
		game_over()
		
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if quantum_acceleration_cooldown > 0:
		quantum_acceleration_cooldown -= delta
	
	if quantum_acceleration_active:
		quantum_acceleration_timer -= delta
		update_quantum_particles(delta)
		
		if quantum_acceleration_timer <= 0:
			deactivate_quantum_acceleration()
	
	if portal_timer > 0:
		portal_timer -= delta
		if portal_timer <= 0:
			reset_portals()
	
	update_portal_indicator()
	
	if Input.is_action_just_pressed("ui_accept") and Global.weapon == 'portal' and progress_bar.value >= PORTAL_COST:
		if not portal_shoot_timeout:
			progress_bar.value -= PORTAL_COST
			if Global.portals == 1:
				portal_shoot_timeout = true
				portal_shoot_timeout_func()
			create_portal()
		else:
			var warning = Label.new()
			warning.text = "Portal shoot timeout!"
			warning.position = Vector2(-50, -50)
			warning.modulate = Color(1, 0.3, 0.3)
			add_child(warning)
			
			var warning_tween = create_tween()
			warning_tween.tween_property(warning, "modulate:a", 0, 1.0)
			warning_tween.tween_callback(warning.queue_free)
	
	if Input.is_action_just_pressed("ui_accept") and Global.weapon == 'punch' and progress_bar.value >= ATTACK_COST and attack_cooldown <= 0:
		progress_bar.value -= ATTACK_COST
		energy_attack()
		attack_cooldown = attack_cooldown_time
	
	if Input.is_action_just_pressed("end") and progress_bar.value >= quantum_acceleration_cost and quantum_acceleration_cooldown <= 0:
		activate_quantum_acceleration()
	
	if can_teleport_timer and Global.portals >= 2:
		if global_position.distance_to(Global.portal1) < 50 and Global.portal2 != Vector2.ZERO:
			teleport_to(Global.portal2)
		elif global_position.distance_to(Global.portal2) < 50 and Global.portal1 != Vector2.ZERO:
			teleport_to(Global.portal1)
	
	if not Global.dead:
		handle_normal_movement(delta)

	if progress_bar.value < 100:
		progress_bar.value += RECHARGE_RATE * delta

func activate_quantum_acceleration():
	if quantum_acceleration_active or quantum_acceleration_cooldown > 0 or progress_bar.value < quantum_acceleration_cost:
		return
		
	progress_bar.value -= quantum_acceleration_cost
	quantum_acceleration_active = true
	quantum_acceleration_timer = quantum_acceleration_duration
	
	speed_multiplier = 1.5
	jump_multiplier = 1.3
	attack_multiplier = 1.5
	portal_range_multiplier = 1.5
	
	create_quantum_field()
	
	sprite_2d.modulate = Color(1.0, 0.5, 0.8, 0.9)
	
	var flash = ColorRect.new()
	flash.color = Color(1.0, 0.5, 0.8, 0.5)
	flash.size = Vector2(100, 100)
	flash.position = Vector2(-50, -50)
	add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.5)
	flash_tween.tween_callback(flash.queue_free)

func portal_shoot_timeout_func():
	await get_tree().create_timer(15).timeout
	portal_shoot_timeout = false

func deactivate_quantum_acceleration():
	if not quantum_acceleration_active:
		return
		
	quantum_acceleration_active = false
	quantum_acceleration_cooldown = quantum_acceleration_cooldown_time
	
	speed_multiplier = 1.0
	jump_multiplier = 1.0
	attack_multiplier = 1.0
	portal_range_multiplier = 1.0
	
	sprite_2d.modulate = Color(1, 1, 1, 1)
	
	for particle in quantum_particles:
		if is_instance_valid(particle):
			var particle_tween = create_tween()
			particle_tween.tween_property(particle, "modulate:a", 0.0, 0.3)
			particle_tween.tween_callback(particle.queue_free)
	
	quantum_particles.clear()



func create_quantum_field():
	for i in range(10):
		var particle = ColorRect.new()
		particle.color = Color(1.0, 0.5, 0.8, 0.7)
		particle.size = Vector2(5, 5)
		
		var angle = randf() * 2 * PI
		var distance = randf_range(30, 50)
		var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
		
		particle.position = pos
		add_child(particle)
		quantum_particles.append(particle)



func update_quantum_particles(delta):
	for particle in quantum_particles:
		if is_instance_valid(particle):
			var current_pos = particle.position
			var angle = current_pos.angle() + delta * 2
			var distance = current_pos.length()
			
			particle.position = Vector2(cos(angle) * distance, sin(angle) * distance)
			
			var size_scale = randf_range(0.8, 1.2)
			particle.size = Vector2(5, 5) * size_scale



func get_special_ability_state():
	return {
		"active": quantum_acceleration_active,
		"cooldown": quantum_acceleration_cooldown,
		"duration": quantum_acceleration_timer if quantum_acceleration_active else 0
	}



func update_portal_indicator():
	var indicator = get_node_or_null("PortalIndicator")
	if indicator:
		if Input.is_action_pressed("ui_accept") and progress_bar.value >= PORTAL_COST and portal_count < max_portals_per_level:
			indicator.visible = true
			
			mouse_pos = get_global_mouse_position()
			var dir_to_portal = global_position.direction_to(mouse_pos)
			
			var current_max_distance = max_portal_distance * portal_range_multiplier
			
			ray_cast.target_position = dir_to_portal * current_max_distance
			ray_cast.force_raycast_update()
			
			indicator.clear_points()
			indicator.add_point(Vector2.ZERO)
			
			if ray_cast.is_colliding():
				var collision_point = ray_cast.get_collision_point() - global_position
				indicator.add_point(collision_point)
			else:
				indicator.add_point(dir_to_portal * current_max_distance)
		else:
			indicator.visible = false



func create_portal() -> void:

	mouse_pos = get_global_mouse_position()
	var dir_to_portal = global_position.direction_to(mouse_pos)
	
	var current_max_distance = max_portal_distance * portal_range_multiplier
	
	ray_cast.target_position = dir_to_portal * current_max_distance
	ray_cast.force_raycast_update()
	
	if ray_cast.is_colliding():
		current_portal_pos = ray_cast.get_collision_point()
		
		match Global.portals:
			0:
				portal1 = current_portal_pos
				Global.portals = 1
				portal_count += 1
			1:
				portal2 = current_portal_pos
				Global.portals = 2
				portal_count += 1
			2:
				portal1 = current_portal_pos
				portal2 = Vector2.ZERO
				Global.portals = 1
				portal_count += 1

		Global.portal1 = portal1
		Global.portal2 = portal2
		Global.shoot_portal = [true, global_position]
		
		spawn_portal_effect(current_portal_pos)
		
		portal_timer = portal_lifetime



func reset_portals():
	portal1 = Vector2.ZERO
	portal2 = Vector2.ZERO
	Global.portal1 = Vector2.ZERO
	Global.portal2 = Vector2.ZERO
	Global.portals = 0
	
	var portals = get_tree().get_nodes_in_group("portals")
	for portal in portals:
		if portal.has_method("fade_out_and_destroy"):
			portal.fade_out_and_destroy()

func energy_attack() -> void:
	var hit_enemy := false
	
	var current_attack_damage = attack_damage * attack_multiplier
	var current_attack_radius = attack_radius * (1.2 if quantum_acceleration_active else 1.0)
	
	var attack_effect = ColorRect.new()
	attack_effect.color = Color(0.2, 0.6, 1.0, 0.4)
	
	if quantum_acceleration_active:
		attack_effect.color = Color(1.0, 0.5, 0.8, 0.4)
	
	attack_effect.size = Vector2(current_attack_radius * 2, current_attack_radius * 2)
	attack_effect.position = Vector2(-current_attack_radius, -current_attack_radius)
	add_child(attack_effect)
	
	var tween = create_tween()
	tween.tween_property(attack_effect, "color:a", 0.0, 0.3)
	tween.tween_callback(attack_effect.queue_free)
	
	for node in get_parent().get_children():
		if node is Area2D and node.has_method("enemy_damage"):

			var direction = node.global_position - global_position
			var distance = direction.length()
			if distance < current_attack_radius:
				node.enemy_damage(current_attack_damage)
				hit_enemy = true
				spawn_damage_number(node.global_position, current_attack_damage, quantum_acceleration_active)
	
	if has_node("AttackSound"):
		$AttackSound.play()



func teleport_to(destination: Vector2) -> void:
	var teleport_out_effect = ColorRect.new()
	teleport_out_effect.color = Color(0.2, 0.6, 1.0, 0.7)
	
	if quantum_acceleration_active:
		teleport_out_effect.color = Color(1.0, 0.5, 0.8, 0.7)
	
	teleport_out_effect.size = Vector2(40, 80)
	teleport_out_effect.position = Vector2(-20, -40)
	get_parent().add_child(teleport_out_effect)
	teleport_out_effect.global_position = global_position
	
	var tween = create_tween()
	tween.tween_property(teleport_out_effect, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_property(teleport_out_effect, "color:a", 0, 0.1)
	tween.tween_callback(teleport_out_effect.queue_free)
	
	global_position = destination
	
	var teleport_in_effect = ColorRect.new()
	teleport_in_effect.color = Color(0.2, 0.6, 1.0, 0.7)
	
	if quantum_acceleration_active:
		teleport_in_effect.color = Color(1.0, 0.5, 0.8, 0.7)
	
	teleport_in_effect.size = Vector2(40, 80)
	teleport_in_effect.position = Vector2(-20, -40)
	teleport_in_effect.scale = Vector2(0.1, 0.1)
	get_parent().add_child(teleport_in_effect)
	teleport_in_effect.global_position = global_position
	
	var tween2 = create_tween()
	tween2.tween_property(teleport_in_effect, "scale", Vector2(1.0, 1.0), 0.2)
	tween2.tween_property(teleport_in_effect, "color:a", 0, 0.3)
	tween2.tween_callback(teleport_in_effect.queue_free)
	
	can_teleport_timer = false
	teleport_timer()

func spawn_portal_effect(pos: Vector2) -> void:
	var portal_effect = ColorRect.new()
	portal_effect.color = Color(0.2, 0.6, 1.0, 0.7)
	
	if quantum_acceleration_active:
		portal_effect.color = Color(1.0, 0.5, 0.8, 0.7)
	
	portal_effect.size = Vector2(60, 60)
	portal_effect.position = Vector2(-30, -30)
	get_parent().add_child(portal_effect)
	portal_effect.global_position = pos
	
	var tween = create_tween()
	tween.tween_property(portal_effect, "size", Vector2(30, 30), 0.3)
	tween.tween_property(portal_effect, "position", Vector2(-15, -15), 0.3)
	tween.tween_property(portal_effect, "color:a", 0, 0.2)
	tween.tween_callback(portal_effect.queue_free)

func spawn_damage_number(pos: Vector2, damage: int, is_critical: bool = false) -> void:
	var damage_instance = damage_number_scene.instantiate()
	damage_instance.position = pos + Vector2(0, -20)
	
	if damage_instance.has_method("set_damage"):
		damage_instance.set_damage(damage, is_critical)
	elif damage_instance.has_method("set_damage_value"):
		damage_instance.set_damage_value(damage)
	
	get_parent().add_child(damage_instance)

func handle_normal_movement(delta: float) -> void:
	var current_jump_velocity = JUMP_VELOCITY * jump_multiplier
	var current_speed = SPEED * speed_multiplier
	
	if Input.is_action_just_pressed("ui_up") and (is_on_floor() or coyote):
		velocity.y = current_jump_velocity
		jumping = true
		
	if Input.is_action_just_released('ui_up') and jumping:
		velocity.y = 0
		jumping = false
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * current_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	get_right_direc(direction)
	move_and_slide()

func coyote_change():
	await get_tree().create_timer(0.5).timeout
	coyote = false

func game_over() -> void:
	Global.dead = true
	Global.coins_collected = 0
	await get_tree().create_timer(3.0).timeout
	global_position = spawn_pos
	health_bar.value = health_bar.max_value
	Global.dead = false

func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

func coin_collected(num):
	coins += num
	Global.coins_collected = coins
	$"+1".visible = true
	$collect.start()

func _on_collect_timeout() -> void:
	$"+1".visible = false

func player_damage(number):
	if is_invulnerable:
		return
	health_bar.value -= number
	is_invulnerable = true
	
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite_2d, "modulate", Color(1, 0.3, 0.3, 0.7), 0.1)
	flash_tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.1)
	
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false

func teleport_timer():
	var current_cooldown = teleport_cooldown
	if quantum_acceleration_active:
		current_cooldown *= 0.5
		
	await get_tree().create_timer(current_cooldown).timeout
	can_teleport_timer = true

func enemy_damage(damage_amount):
	player_damage(damage_amount)

func _on_level_changed():
	portal_count = 0
	reset_portals()
	
	if quantum_acceleration_active:
		deactivate_quantum_acceleration()
	quantum_acceleration_cooldown = 0.0
	
	
func teleport_to_spawn():
	return spawn_pos
