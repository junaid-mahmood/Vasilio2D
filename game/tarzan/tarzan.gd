extends CharacterBody2D

var DISTANCE_GRAPPLE: int
var GRAPPLE_POS: Vector2
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var ray_cast = $grapple
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var rope_length = 300
var current_rope_length = 0 
var hooked := false
var was_hooked := false
var is_grappling := false
var current_grappling_point := Vector2.ZERO
var motion = Vector2.ZERO
var motion_graple = Vector2.ZERO
var mouse_pos := Vector2.ZERO
var grapple_speed = 500
var previous_pos := Vector2.ZERO
var facing_right := false
var coyote := true
var jumping := false
var spawn_pos = Vector2.ZERO

var weapons = ['hook', 'grapple', 'punch']
var weapon_counter := 0

var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var can_change_ani := true

var coins := 0

var speed_multiplier := 1.0
var jump_multiplier:= 1.0
var rope_length_multiplier := 1.0
var acceleration_multiplier := 1.0


func _ready() -> void:
	add_to_group("player")
	spawn_pos = global_position
	
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	Global.has_shield = false
	Global.weapon = 'hook'


func coyote_change():
	await get_tree().create_timer(0.2).timeout
	coyote = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Q:
				switch_to_weapon("hook")
			elif event.keycode == KEY_R:
				switch_to_weapon("grapple")
			elif event.keycode == KEY_C:
				switch_to_weapon("punch")
				
func switch_to_weapon(weapon_name: String) -> void:
	if weapons.has(weapon_name):
		Global.weapon = weapon_name
		match weapon_name:
			'hook':
				weapon_counter = 0
			'grapple':
				weapon_counter = 1
			'punch':
				weapon_counter = 2

func _process(delta: float) -> void:
	match Global.weapon:
		'hook':
			weapon_counter = 0
		'grapple':
			weapon_counter = 1
		'punch':
			weapon_counter = 2
	
	Global.player_position = position
	if is_on_floor():
		coyote = true
		jumping = false
	else:
		coyote_change()
		jump_catch()

		
	if health_bar.value <= 0:
		game_over()
		
	if Input.is_action_just_released("ui_accept") and hooked: 
		hooked = false
		motion = Vector2.ZERO
		$"extra+damage".start()
	
	if Input.is_action_just_pressed("KEY_F") and progress_bar.value >= 50:
		activate_special_ability()
	
	
	#hook
	if Input.is_action_just_pressed("ui_accept") and progress_bar.value >= 10 and weapons[weapon_counter] == "hook":
		progress_bar.value -= 10
		mouse_pos = get_global_mouse_position()
		var dir_to_grapple = global_position.direction_to(mouse_pos)
		ray_cast.target_position = dir_to_grapple * rope_length * rope_length_multiplier
		ray_cast.force_raycast_update()
		var collision_object = ray_cast.get_collider()

		if ray_cast.is_colliding():
			GRAPPLE_POS = ray_cast.get_collision_point()
			DISTANCE_GRAPPLE = global_position.distance_to(GRAPPLE_POS)
			current_rope_length = DISTANCE_GRAPPLE  
			hooked = true
			was_hooked = true
			motion = velocity 
			create_swing_trail()
			create_hit_effect(GRAPPLE_POS)
			
		
	#attack move
	if Input.is_action_just_pressed("ui_accept") and weapons[weapon_counter] == "punch": 
		mouse_pos = get_global_mouse_position()
		var centered_global_position = global_position

		var direc_to_mouse = (mouse_pos - centered_global_position).normalized()
		var angle_radians = atan2(direc_to_mouse.y, direc_to_mouse.x)
		var shield_pos = centered_global_position + Vector2(cos(angle_radians), sin(angle_radians)) * 150	# 150 is distance from player
		$attack_ray.target_position = to_local(shield_pos)
		$attack_ray.force_raycast_update()
		var collision_object = $attack_ray.get_collider()
		
		var hit_effect2 = ColorRect.new()
		hit_effect2.color = Color(1.0, 0.5, 0.0, 0.7)
		hit_effect2.size = Vector2(4, 4)
		get_parent().add_child(hit_effect2)
		hit_effect2.global_position = to_global($attack_ray.target_position)
		var hit_tween2 = create_tween()
		hit_tween2.tween_property(hit_effect2, "color:a", 0.0, 0.3)
		hit_tween2.tween_callback(hit_effect2.queue_free)

		if $attack_ray.is_colliding():
			attack_ani(shield_pos)
			if collision_object != null:
				if collision_object.is_in_group("enemies") or collision_object.has_method('im_jungle_enemy'):
					collision_object.enemy_damage(25)
		else:
			attack_ani(shield_pos)

		
		
		
	#grapping - getting pulled towards a point
	if Input.is_action_pressed("ui_accept") and progress_bar.value >= 100 and weapons[weapon_counter] == "grapple":
		progress_bar.value -= 100
		mouse_pos = get_global_mouse_position()
		var dir_to_grapple = global_position.direction_to(mouse_pos)
		ray_cast.target_position = dir_to_grapple * rope_length * rope_length_multiplier
		ray_cast.force_raycast_update()
		var collision_object = ray_cast.get_collider()
		
		if ray_cast.is_colliding():
			current_grappling_point = ray_cast.get_collision_point()
			current_rope_length = global_position.distance_to(current_grappling_point)
			is_grappling = true
		
			
			
	
		
	if not Global.dead:
		if is_grappling:
			current_rope_length = global_position.distance_to(current_grappling_point)
			swing_grapple(delta)
			var dir_to_grappling = global_position.direction_to(current_grappling_point)
			velocity = dir_to_grappling * grapple_speed
			if global_position.distance_to(current_grappling_point) < 50 or previous_pos == position:
				is_grappling = false
			previous_pos = position
		if hooked:
			current_rope_length = global_position.distance_to(GRAPPLE_POS)
			swing(delta)
			queue_redraw() 
		else:
			handle_normal_movement(delta)
		
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0
		
		
		
	if $Sprite2D.animation != 'die' and $Sprite2D.animation != 'hit':
		if not is_on_floor():
			$Sprite2D.animation = 'idle'
		elif abs(velocity.x) > 1:
			$Sprite2D.animation = 'run'
		else:
			$Sprite2D.animation = 'idle'
	
	queue_redraw()
	if progress_bar.value <= 100:
		progress_bar.value += 1



func handle_normal_movement(delta: float) -> void:
	if Input.is_action_just_pressed("ui_up") and (is_on_floor() or coyote):
		velocity.y = JUMP_VELOCITY * jump_multiplier
		jumping = true
		
	if Input.is_action_just_released('ui_up') and jumping:
		velocity.y = 0
		jumping = false
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED * speed_multiplier, (ACCELERATION * delta) * acceleration_multiplier)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func activate_special_ability():
	progress_bar.value -= 50
	create_special_ability_effects()
	play_special_ability_sound()

	speed_multiplier = 1.5
	jump_multiplier = 1.2
	rope_length_multiplier = 1.5
	acceleration_multiplier = 1.5
	is_invulnerable = true

	await get_tree().create_timer(3.0).timeout

	speed_multiplier = 1.0
	jump_multiplier = 1.0
	rope_length_multiplier = 1.0
	acceleration_multiplier = 1.0
	
	await get_tree().create_timer(0.5).timeout
	is_invulnerable = false



func play_special_ability_sound():
	var sound = get_node_or_null("VineSound")
	if sound and sound is AudioStreamPlayer:
		sound.pitch_scale = 0.7
		sound.volume_db = 0.0
		sound.play()
		
		var tween = create_tween()
		tween.tween_interval(0.5)
		tween.tween_property(sound, "volume_db", -5.0, 0.5)




func game_over() -> void:
	$Sprite2D.animation = 'die'
	Global.dead = true
	Global.coins_collected = 0
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
	Global.dead = false


func swing(delta: float) -> void:
	motion.y += gravity * delta * 0.5
	
	var radius = global_position - GRAPPLE_POS
	
	if motion.length() < 0.01 or radius.length() < 10:
		return
	
	var angle = acos(clamp(radius.dot(motion) / (radius.length() * motion.length()), -1.0, 1.0))
	var rad_vel = cos(angle) * motion.length()
	
	motion += radius.normalized() * -rad_vel
	
	var tangent = Vector2(-radius.y, radius.x).normalized()
	var direction = sign(tangent.dot(motion))
	var swing_boost = 200 * delta * direction
	motion += tangent * swing_boost
	
	if global_position.distance_to(GRAPPLE_POS) > current_rope_length:
		global_position = GRAPPLE_POS + radius.normalized() * current_rope_length
	
	motion += (GRAPPLE_POS - global_position).normalized() * 8000 * delta
	velocity = motion
	move_and_slide()

func _draw() -> void:
	if hooked:
		var line = Line2D.new()
		line.width = 5.0
		line.default_color = Color(0.2, 0.8, 0.2, 0.8)
		line.add_point(Vector2.ZERO)
		line.add_point(to_local(GRAPPLE_POS))
		add_child(line)
		
		var tween = create_tween()
		tween.tween_property(line, "width", 3.0, 0.03)
		tween.parallel().tween_property(line, "default_color:a", 0.0, 0.06)
		tween.tween_callback(line.queue_free)
	elif is_grappling:
		var line = Line2D.new()
		line.width = 5.0
		line.default_color = Color(0.2, 0.8, 0.2, 0.8)
		line.add_point(Vector2.ZERO)
		line.add_point(to_local(current_grappling_point))
		add_child(line)
		
		var tween = create_tween()
		tween.tween_property(line, "width", 3.0, 0.08)
		tween.parallel().tween_property(line, "default_color:a", 0.0, 0.1)
		tween.tween_callback(line.queue_free)


func attack_ani(attack_pos):
	var line = Line2D.new()
	line.width = 5.0
	line.default_color = Color(0.2, 0.8, 0.2, 0.8)
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(attack_pos))
	add_child(line)
	
	var tween = create_tween()
	tween.tween_property(line, "width", 3.0, 0.08)
	tween.parallel().tween_property(line, "default_color:a", 0.0, 0.1)
	tween.tween_callback(line.queue_free)


func swing_grapple(delta: float) -> void:
	var radius = global_position - current_grappling_point
	if radius.length() < 10:
		return
	if global_position.distance_to(current_grappling_point) > current_rope_length:
		global_position = current_grappling_point + radius.normalized() * current_rope_length
		var tangent = Vector2(-radius.y, radius.x).normalized()
		motion_graple = tangent * motion_graple.dot(tangent)
	
	velocity = motion_graple
	move_and_slide()
	




func _on_extradamage_timeout() -> void:
	was_hooked = false
	
func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

func player_damage(number):
	if is_invulnerable:
		return
	health_bar.value -= number
	
	if $Sprite2D.animation != 'die':
		$Sprite2D.animation = 'hit'
		await get_tree().create_timer(0.5).timeout
		$Sprite2D.animation = 'idle'
		
	is_invulnerable = true
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false

func coin_collected(num):
	coins += num
	Global.coins_collected = coins
	$"+1".visible = true
	$collect.start()

func jump_catch():
	if ($catch_jump/right.is_colliding() or $catch_jump/left.is_colliding()) and jumping:
		position.y -= 3
		


func _on_collect_timeout() -> void:
	$"+1".visible = false


func create_special_ability_effects():
	var particles = CPUParticles2D.new()
	particles.name = "SpecialParticles"
	particles.amount = 30
	particles.lifetime = 1.0
	particles.explosiveness = 0.2
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 50)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.0, 0.8, 0.2, 0.8)
	add_child(particles)
	
	# Create a tween to fade out the particles
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(particles.queue_free)
	
	# Create a glow effect
	var glow = PointLight2D.new()
	glow.name = "SpecialGlow"
	glow.texture = null
	glow.color = Color(0.0, 0.8, 0.2, 0.5)
	glow.energy = 0.8
	glow.texture_scale = 2.0
	add_child(glow)
	
	# Create a tween to fade out the glow
	var glow_tween = create_tween()
	glow_tween.tween_property(glow, "energy", 0.0, 3.0)
	glow_tween.tween_callback(glow.queue_free)
	
	
	
func create_swing_trail():
	if not hooked:
		return
		
	# Create a trail particle at the current position
	var trail_particle = ColorRect.new()
	trail_particle.color = Color(0.2, 0.7, 0.9, 0.3)
	trail_particle.size = Vector2(10, 10)
	trail_particle.position = Vector2(-5, -5)
	get_parent().add_child(trail_particle)
	trail_particle.global_position = global_position
	
	# Create a tween to fade out and remove the trail particle
	var tween = create_tween()
	tween.tween_property(trail_particle, "color:a", 0.0, 0.5)
	tween.tween_callback(trail_particle.queue_free)
	
	# Schedule the next trail particle
	if hooked:
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(self) and hooked:
			create_swing_trail()
			
			
func create_hit_effect(new_hit_effect_pos):
	var hit_effect = ColorRect.new()
	hit_effect.color = Color(1.0, 0.5, 0.0, 0.7)
	hit_effect.size = Vector2(8, 8)
	get_parent().add_child(hit_effect)
	hit_effect.global_position = new_hit_effect_pos
	
	var hit_tween = create_tween()
	hit_tween.tween_property(hit_effect, "color:a", 0.0, 0.3)
	hit_tween.tween_callback(hit_effect.queue_free)
	
	
func teleport_to_spawn():
	return spawn_pos
