extends CharacterBody2D

signal weapon_changed(new_weapon)

var facing_right = true
var coins := 0

var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var DISTANCE_SHIELD := 40
var weapons = ["gun", "sword", "shield", "bow"]

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 50.0 
const SHOOT_COST := 20.0
const SWORD_COST := 40.0
const DOUBLE_JUMP_COST := 40.0
const BOW_COST := 25.0

const MAX_CHARGE_TIME := 1.5  
const MIN_CHARGE_TIME := 0.2  
const CHARGE_SWORD_RADIUS_MULTIPLIER := 1.5 
const CHARGE_SWORD_DAMAGE_MULTIPLIER := 2.0  
const CHARGE_BOW_SPEED_MULTIPLIER := 2.0  
const CHARGE_BOW_DAMAGE_MULTIPLIER := 2.0  

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var bow_sprite = null
var bow_character_sprite = null
var bow_character_texture = null  
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_double_jump := false
var jump_timer := 0.0
var recently_jumped := false
var weapon_counter := 0
var shield_body = null
var transitioning = false
var fade_rect = null
var has_gun = false
var has_bow = true
var current_weapon = "bow"
var weapon_switch_cooldown = 0.0
var last_weapon_switch_time = 0.0

var is_charging := false
var charge_start_time := 0.0
var current_charge := 0.0
var charge_effect = null

var damage_number_scene = preload("res://damage_number.tscn")

func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	add_to_group("player")
	
	var parent = get_parent()
	shield_body = parent.get_node_or_null("shield")
	if shield_body != null:
		shield_body.visible = false

	if has_node("BowSprite"):
		$BowSprite.queue_free()
		
	var bow_texture = preload("res://assets/bow.png")
	bow_sprite = Sprite2D.new()
	bow_sprite.name = "BowSprite"
	bow_sprite.texture = bow_texture
	bow_sprite.scale = Vector2(0.75, 0.75)  
	add_child(bow_sprite)
	
	create_static_bow_character()
	
	setup_charge_effect()

	current_weapon = "bow"
	Global.weapon = "bow"
	weapon_counter = weapons.find("bow")
	
	weapon_changed.connect(_on_weapon_changed)
	
	setup_transition_layer()
	
	bow_sprite.visible = true
	update_bow_position_and_rotation()
	
	if bow_character_sprite:
		bow_character_sprite.visible = true
		sprite_2d.visible = false

func create_static_bow_character():
	if has_node("BowCharacterSprite"):
		$BowCharacterSprite.queue_free()
	
	var frames = sprite_2d.sprite_frames
	if frames.has_animation("bow"):
		bow_character_texture = frames.get_frame_texture("bow", 0)
	else:
		bow_character_texture = frames.get_frame_texture("default", 0)
	
	bow_character_sprite = Sprite2D.new()
	bow_character_sprite.name = "BowCharacterSprite"
	bow_character_sprite.texture = bow_character_texture
	
	bow_character_sprite.position = sprite_2d.position
	bow_character_sprite.z_index = sprite_2d.z_index
	
	bow_character_sprite.scale = sprite_2d.scale
	
	bow_character_sprite.offset = sprite_2d.offset
	bow_character_sprite.centered = sprite_2d.centered
	
	add_child(bow_character_sprite)
	
	bow_character_sprite.visible = false
	

func setup_charge_effect():
	charge_effect = ColorRect.new()
	charge_effect.name = "ChargeEffect"
	charge_effect.color = Color(1, 0.5, 0, 0.0)  
	charge_effect.size = Vector2(40, 40)
	charge_effect.position = Vector2(-20, -20)
	charge_effect.visible = false
	add_child(charge_effect)

func _on_weapon_changed(new_weapon):
	current_weapon = new_weapon
	Global.weapon = new_weapon
	
	if new_weapon == "bow":
		if bow_character_sprite:
			bow_character_sprite.flip_h = sprite_2d.flip_h
			bow_character_sprite.visible = true
			sprite_2d.visible = false
		
		if not bow_sprite or not is_instance_valid(bow_sprite):
			var bow_texture = preload("res://assets/bow.png")
			bow_sprite = Sprite2D.new()
			bow_sprite.name = "BowSprite"
			bow_sprite.texture = bow_texture
			bow_sprite.scale = Vector2(0.75, 0.75)
			add_child(bow_sprite)
		
		bow_sprite.visible = true
		update_bow_position_and_rotation()
	else:
		if bow_character_sprite:
			bow_character_sprite.visible = false
			sprite_2d.visible = true
		
		if bow_sprite and is_instance_valid(bow_sprite):
			bow_sprite.visible = false

func setup_transition_layer():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "TransitionLayer"
	add_child(canvas_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	canvas_layer.add_child(fade_rect)
	
	get_viewport().size_changed.connect(update_fade_rect_size)
	update_fade_rect_size()

func update_fade_rect_size():
	if fade_rect:
		fade_rect.size = get_viewport_rect().size
		fade_rect.position = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if Time.get_ticks_msec() - last_weapon_switch_time < 300: 
		return
		
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Q:
				print("Q pressed - switching to sword")
				weapon_counter = weapons.find("sword")
				switch_to_weapon("sword")
				sprite_2d.animation = "sword"
				sprite_2d.frame = 0  
				if bow_character_sprite:
					bow_character_sprite.visible = false
					sprite_2d.visible = true
				if shield_body != null:
					shield_body.visible = false
					Global.has_shield = false
				last_weapon_switch_time = Time.get_ticks_msec()
			elif event.keycode == KEY_R:
				weapon_counter = weapons.find("bow")
				switch_to_weapon("bow")
				if bow_sprite and is_instance_valid(bow_sprite):
					bow_sprite.visible = true
					update_bow_position_and_rotation()
				if bow_character_sprite:
					bow_character_sprite.visible = true
					sprite_2d.visible = false
				last_weapon_switch_time = Time.get_ticks_msec()
			elif event.keycode == KEY_C:
				weapon_counter = weapons.find("shield")
				switch_to_weapon("shield")
				if bow_character_sprite:
					bow_character_sprite.visible = false
					sprite_2d.visible = true
				if shield_body != null:
					shield_body.visible = true
					Global.has_shield = true
				last_weapon_switch_time = Time.get_ticks_msec()

func update_bow_position_and_rotation():
	if not bow_sprite or not is_instance_valid(bow_sprite):
		return 0
		
	var mouse_pos = get_viewport().get_mouse_position()
	
	var centered_position = global_position + Vector2(0, -10)
	var direction_to_mouse = (mouse_pos - centered_position).normalized()
	
	var angle_radians = atan2(direction_to_mouse.y, direction_to_mouse.x)
	
	var should_face_right = mouse_pos.x > centered_position.x
	
	if bow_character_sprite and current_weapon == "bow":
		bow_character_sprite.visible = true
		bow_character_sprite.flip_h = !should_face_right
		sprite_2d.visible = false
	
	if should_face_right:
		angle_radians = clamp(angle_radians, -PI/2, PI/2)
		facing_right = true
		if bow_character_sprite:
			bow_character_sprite.flip_h = false
	else:
		if angle_radians < 0:
			angle_radians = clamp(angle_radians, -PI, -PI/2)
		else:
			angle_radians = clamp(angle_radians, PI/2, PI)
		facing_right = false
		if bow_character_sprite:
			bow_character_sprite.flip_h = true
	
	bow_sprite.rotation = angle_radians
	
	var bow_offset = Vector2(15, 0).rotated(angle_radians)
	bow_sprite.position = Vector2(0, -10) + bow_offset
	
	bow_sprite.flip_v = !facing_right
	
	return angle_radians


func _physics_process(delta: float) -> void:
	if transitioning:
		return
		
	check_door_collision()

	if health_bar.value <= 0:
		game_over()
	
	if Global.weapon != current_weapon:
		Global.weapon = current_weapon
	
	if current_weapon == "bow":
		if not bow_sprite or not is_instance_valid(bow_sprite):
			var bow_texture = preload("res://assets/bow.png")
			bow_sprite = Sprite2D.new()
			bow_sprite.name = "BowSprite"
			bow_sprite.texture = bow_texture
			bow_sprite.scale = Vector2(0.75, 0.75)
			add_child(bow_sprite)
		
		bow_sprite.visible = true
		var angle = update_bow_position_and_rotation()
		
		if bow_character_sprite:
			bow_character_sprite.visible = true
			sprite_2d.visible = false
			
			if not bow_character_sprite.visible:
				bow_character_sprite.visible = true
	else:
		if bow_sprite and is_instance_valid(bow_sprite):
			bow_sprite.visible = false
		
		if bow_character_sprite:
			bow_character_sprite.visible = false
			sprite_2d.visible = true
	
	if is_charging:
		var charge_time = Time.get_ticks_msec() / 1000.0 - charge_start_time
		current_charge = clamp(charge_time, 0, MAX_CHARGE_TIME)
		
		if charge_effect:
			var charge_percent = (current_charge - MIN_CHARGE_TIME) / (MAX_CHARGE_TIME - MIN_CHARGE_TIME)
			if charge_percent > 0:
				charge_effect.visible = true
				charge_effect.color.a = charge_percent * 0.5
				
				var scale_factor = 1.0 + charge_percent
				charge_effect.size = Vector2(40, 40) * scale_factor
				charge_effect.position = Vector2(-20, -20) * scale_factor
				
				if current_weapon == "sword":
					charge_effect.color = Color(1, 0.5, 0, charge_effect.color.a) 
				elif current_weapon == "bow":
					charge_effect.color = Color(0, 0.7, 1, charge_effect.color.a)  
			else:
				charge_effect.visible = false
	
	if shield_body != null:
		var centered_global_position = global_position
		centered_global_position.y -= 20
		centered_global_position.x += 9
		var mouse_pos = get_viewport().get_mouse_position()
		var direc_to_mouse = (mouse_pos - centered_global_position).normalized()
		var angle_radians = atan2(direc_to_mouse.y, direc_to_mouse.x)
		var shield_pos = centered_global_position + Vector2(cos(angle_radians), sin(angle_radians)) * DISTANCE_SHIELD
		shield_body.position = shield_pos
		if angle_radians:
			shield_body.rotation = angle_radians
		
		if current_weapon == 'shield':
			shield_body.visible = true
			Global.has_shield = true
		else:
			shield_body.visible = false
			Global.has_shield = false

	if Input.is_action_just_pressed("bow_select") and Time.get_ticks_msec() - last_weapon_switch_time >= 300:
		switch_to_weapon("bow")
		last_weapon_switch_time = Time.get_ticks_msec()
	
	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	if not is_on_floor():
		velocity.y += gravity * delta
		if current_weapon == 'bow':
			if bow_character_sprite:
				bow_character_sprite.visible = true
				sprite_2d.visible = false
			else:
				sprite_2d.animation = "jumping"
		else:
			sprite_2d.animation = "jumping"
		if bow_character_sprite:
			bow_character_sprite.visible = false
	elif current_weapon == 'sword':
		sprite_2d.animation = "sword"
		sprite_2d.visible = true
		# Hide bow character sprite
		if bow_character_sprite:
			bow_character_sprite.visible = false
	elif current_weapon == 'bow':
		if bow_character_sprite:
			bow_character_sprite.visible = true
			sprite_2d.visible = false
			
			# EMERGENCY FIX: Force visibility every frame
			if not bow_character_sprite.visible:
				bow_character_sprite.visible = true
		else:
			sprite_2d.animation = "bow"
		sprite_2d.visible = true
		if not sprite_2d.is_playing():
			sprite_2d.play("bow")
	elif abs(velocity.x) > 1 and not Global.dead:
		sprite_2d.animation = "running"
		sprite_2d.visible = true
		if bow_character_sprite:
			bow_character_sprite.visible = false
	else:
		sprite_2d.animation = "default"
		sprite_2d.visible = true
		if bow_character_sprite:
			bow_character_sprite.visible = false
	
	if is_on_floor():
		can_double_jump = true
		recently_jumped = false
	
	if recently_jumped:
		jump_timer += delta
		if jump_timer >= 0.5:
			recently_jumped = false
			jump_timer = 0.0

	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			$Jump1.play()
			velocity.y = JUMP_VELOCITY
			recently_jumped = true
			jump_timer = 0.0
		elif can_double_jump and progress_bar.value >= DOUBLE_JUMP_COST:
			$Jump2.play()
			velocity.y = JUMP_VELOCITY * 1.1
			progress_bar.value -= DOUBLE_JUMP_COST
			can_double_jump = false
	
	if Input.is_action_just_pressed("ui_select"):
		if current_weapon == 'sword':
			sprite_2d.animation = 'sword'
			sprite_2d.frame = 0  
		
		is_charging = true
		charge_start_time = Time.get_ticks_msec() / 1000.0
		current_charge = 0.0
	
	if Input.is_action_just_released("ui_select"):
		# Calculate charge percentage (0 to 1)
		var charge_time = current_charge
		var is_charged = charge_time >= MIN_CHARGE_TIME
		var charge_percent = 0.0
		
		if is_charged:
			charge_percent = (charge_time - MIN_CHARGE_TIME) / (MAX_CHARGE_TIME - MIN_CHARGE_TIME)
			charge_percent = clamp(charge_percent, 0.0, 1.0)
		
		if charge_effect:
			charge_effect.visible = false
		
		if current_weapon == 'gun' and has_gun:
			progress_bar.value -= SHOOT_COST
			$Shoot.play()
			Global.shoot = [true, global_position, facing_right]
		elif current_weapon == 'bow' and has_bow and progress_bar.value >= BOW_COST:
			progress_bar.value -= BOW_COST
			$Shoot.play()
			
			var mouse_pos = get_viewport().get_mouse_position()
			
			var centered_position = global_position + Vector2(0, -10)
			var direction_to_mouse = (mouse_pos - centered_position).normalized()
			
			var angle_radians = atan2(direction_to_mouse.y, direction_to_mouse.x)
			
			if facing_right:
				angle_radians = clamp(angle_radians, -PI/2, PI/2)
			else:
				if angle_radians < 0:
					angle_radians = clamp(angle_radians, -PI, -PI/2)
				else:
					angle_radians = clamp(angle_radians, PI/2, PI)
			
			var limited_direction = Vector2(cos(angle_radians), sin(angle_radians))
			
			var speed_multiplier = 1.0
			var damage_multiplier = 1.0
			if is_charged:
				speed_multiplier = 1.0 + charge_percent * (CHARGE_BOW_SPEED_MULTIPLIER - 1.0)
				damage_multiplier = 1.0 + charge_percent * (CHARGE_BOW_DAMAGE_MULTIPLIER - 1.0)
				print("Charged bow shot! Speed: " + str(speed_multiplier) + "x, Damage: " + str(damage_multiplier) + "x")
			
			if bow_sprite and is_instance_valid(bow_sprite):
				var spawn_pos = global_position + bow_sprite.position
				
				Global.shoot = [true, spawn_pos, spawn_pos + limited_direction * 1000 * speed_multiplier, damage_multiplier]
			else:
				Global.shoot = [true, global_position + Vector2(0, -10), global_position + Vector2(0, -10) + limited_direction * 1000 * speed_multiplier, damage_multiplier]

		elif current_weapon == 'sword':
			progress_bar.value -= SWORD_COST
			sprite_2d.animation = "sword"
			sprite_2d.frame = 0 
			
			var kill_radius: float = 70.0
			var damage: float = 50.0
			
			if is_charged:
				var radius_multiplier = 1.0 + charge_percent * (CHARGE_SWORD_RADIUS_MULTIPLIER - 1.0)
				var damage_multiplier = 1.0 + charge_percent * (CHARGE_SWORD_DAMAGE_MULTIPLIER - 1.0)
				kill_radius *= radius_multiplier
				damage *= damage_multiplier
				print("Charged sword attack! Radius: " + str(radius_multiplier) + "x, Damage: " + str(damage_multiplier) + "x")
				
				var sword_slash = ColorRect.new()
				sword_slash.color = Color(1, 0.5, 0, 0.3)  
				sword_slash.size = Vector2(kill_radius * 2, kill_radius * 2)
				sword_slash.position = Vector2(-kill_radius, -kill_radius)
				add_child(sword_slash)
				
				var tween = create_tween()
				tween.tween_property(sword_slash, "color:a", 0.0, 0.3)
				tween.tween_callback(sword_slash.queue_free)
			
			for node in get_parent().get_children():
				if node is Area2D and node.has_method("enemy_damage"):
					var direction = node.global_position - global_position
					var distance = direction.length()
					if distance < kill_radius:
						node.enemy_damage(damage)
						
						spawn_damage_number(node.global_position, damage, is_charged && charge_percent > 0.5)
			
			sprite_2d.play("sword")
			sprite_2d.frame = 0 
		
		is_charging = false
		current_charge = 0.0

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	if not Global.dead:
		move_and_slide()
		if velocity.x != 0:
			sprite_2d.flip_h = velocity.x < 0
			if bow_character_sprite:
				bow_character_sprite.flip_h = sprite_2d.flip_h
			
	get_right_direc(direction)
	
	Global.player_position = position

func switch_to_weapon(weapon_name: String) -> void:
	if weapons.has(weapon_name):
		print("Switching to weapon: " + weapon_name + " (index: " + str(weapons.find(weapon_name)) + ")")
		
		weapon_changed.emit(weapon_name)
		weapon_counter = weapons.find(weapon_name)
		
		# Handle bow
		if weapon_name == "bow":
			if not bow_sprite or not is_instance_valid(bow_sprite):
				var bow_texture = preload("res://assets/bow.png")
				bow_sprite = Sprite2D.new()
				bow_sprite.name = "BowSprite"
				bow_sprite.texture = bow_texture
				bow_sprite.scale = Vector2(0.75, 0.75)
				add_child(bow_sprite)
			
			bow_sprite.visible = true
			update_bow_position_and_rotation()
			
			if bow_character_sprite:
				bow_character_sprite.visible = true
				sprite_2d.visible = false
		elif weapon_name == "sword":
			sprite_2d.animation = "sword"
			sprite_2d.frame = 0  
			sprite_2d.visible = true
			
			if bow_character_sprite:
				bow_character_sprite.visible = false
			
			if shield_body != null:
				shield_body.visible = false
				Global.has_shield = false
			print("Sword equipped - shield visibility: " + str(shield_body.visible if shield_body != null else "no shield"))
		elif weapon_name == "shield":
			if bow_character_sprite:
				bow_character_sprite.visible = false
				sprite_2d.visible = true
			
			if shield_body != null:
				shield_body.visible = true
				Global.has_shield = true
			print("Shield equipped - shield visibility: " + str(shield_body.visible if shield_body != null else "no shield"))
		else:
			if bow_sprite and is_instance_valid(bow_sprite):
				bow_sprite.visible = false
			
			if bow_character_sprite:
				bow_character_sprite.visible = false
				sprite_2d.visible = true

func check_door_collision():
	var door = get_node_or_null("../Door")
	if door:
		var distance = global_position.distance_to(door.global_position)
		if distance < 50:
			transition_to_level("res://Level2.tscn")

func transition_to_level(next_scene_path: String):
	if transitioning or fade_rect == null:
		return
		
	transitioning = true
	
	update_fade_rect_size()
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(next_scene_path)

func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0
		sprite_2d.flip_h = !facing_right
		
		if bow_character_sprite:
			bow_character_sprite.flip_h = sprite_2d.flip_h

func player_damage(number):
	if is_invulnerable:
		return
	health_bar.value -= number
	var tween = create_tween()
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 0.0, 0.1)
	
	is_invulnerable = true
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false

func game_over() -> void:
	Global.dead = true
	Global.coins_collected = 0
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
	Global.dead = false

func coin_collected(num):
	coins += num
	Global.coins_collected = coins
	$"+1".visible = true
	$collect.start()

func _on_collect_timeout() -> void:
	$"+1".visible = false

func _on_barrel_2_explo_damage(num: Variant) -> void:
	player_damage(num)

func _on_barrel_3_explo_damage(num: Variant) -> void:
	player_damage(num)

func _on_barrel_explo_damage(num: Variant) -> void:
	player_damage(num)

func _process(delta: float) -> void:
	if Global.weapon != current_weapon:
		Global.weapon = current_weapon
	
	if current_weapon == "bow":
		if not bow_sprite or not is_instance_valid(bow_sprite):
			var bow_texture = preload("res://assets/bow.png")
			bow_sprite = Sprite2D.new()
			bow_sprite.name = "BowSprite"
			bow_sprite.texture = bow_texture
			bow_sprite.scale = Vector2(0.75, 0.75)
			add_child(bow_sprite)
		
		bow_sprite.visible = true
		update_bow_position_and_rotation()
		
		if bow_character_sprite:
			bow_character_sprite.visible = true
			sprite_2d.visible = false
			
			if not bow_character_sprite.visible:
				print("EMERGENCY FIX: Bow character sprite was invisible in process, forcing visibility")
				bow_character_sprite.visible = true
	else:
		if bow_character_sprite:
			bow_character_sprite.visible = false
			sprite_2d.visible = true

func spawn_damage_number(pos, damage, is_critical = false):
	var damage_number = damage_number_scene.instantiate()
	
	damage_number.set_damage(round(damage), is_critical)
	
	damage_number.global_position = pos + Vector2(0, -10)
	
	get_tree().get_root().add_child(damage_number)

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible() and not transitioning and not Global.dead:
			set_visible(true)
			if sprite_2d:
				sprite_2d.visible = true
		elif is_visible() and sprite_2d and not sprite_2d.visible and not transitioning and not Global.dead:
			sprite_2d.visible = true

func _ensure_visibility():
	if current_weapon == 'bow' and not transitioning and not Global.dead:
		if sprite_2d:
			sprite_2d.visible = true
			sprite_2d.animation = "bow"
			if not sprite_2d.is_playing():
				sprite_2d.play("bow")
