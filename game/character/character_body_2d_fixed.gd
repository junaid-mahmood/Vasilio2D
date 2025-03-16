extends CharacterBody2D

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

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
@onready var bow_sprite = $BowSprite
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

func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	
	var parent = get_parent()
	shield_body = parent.get_node_or_null("shield")
	if shield_body != null:
		shield_body.visible = false

	if not has_node("BowSprite"):
		var bow_texture = preload("res://assets/bow.png")
		bow_sprite = Sprite2D.new()
		bow_sprite.name = "BowSprite"
		bow_sprite.texture = bow_texture
		bow_sprite.scale = Vector2(1.5, 1.5)
		add_child(bow_sprite)
		print("Created new bow sprite")
	else:
		bow_sprite = $BowSprite
		bow_sprite.scale = Vector2(1.5, 1.5)
		print("Using existing bow sprite")

	# Start with bow as the default weapon
	Global.weapon = "bow"
	weapon_counter = weapons.find("bow")
	
	setup_transition_layer()
	
	# Force bow to be visible at start
	bow_sprite.visible = true
	print("Initial bow visibility set to: " + str(bow_sprite.visible) + " for weapon: " + Global.weapon)

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
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Q:
				switch_to_weapon("sword")
			elif event.keycode == KEY_R:
				switch_to_weapon("bow")
				# Force bow to be visible immediately
				bow_sprite.visible = true
				print("R key pressed - bow should be visible now: " + str(bow_sprite.visible))
			elif event.keycode == KEY_C:
				switch_to_weapon("shield")

func update_bow_position_and_rotation():
	# Get the mouse position in global coordinates
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Calculate direction from player to mouse
	var centered_position = global_position + Vector2(0, -10)
	var direction_to_mouse = (mouse_pos - centered_position).normalized()
	
	# Calculate angle for rotation
	var angle_radians = atan2(direction_to_mouse.y, direction_to_mouse.x)
	
	# Determine which way the player should face based on mouse position
	var should_face_right = mouse_pos.x > centered_position.x
	
	# Limit the bow to only work in a 180-degree arc in front of the player
	if should_face_right:
		# If facing right, limit angle to right hemisphere (-90 to 90 degrees)
		angle_radians = clamp(angle_radians, -PI/2, PI/2)
		sprite_2d.flip_h = false
		facing_right = true
	else:
		# If facing left, limit angle to left hemisphere (90 to 270 degrees)
		if angle_radians < 0:
			angle_radians = clamp(angle_radians, -PI, -PI/2)
		else:
			angle_radians = clamp(angle_radians, PI/2, PI)
		sprite_2d.flip_h = true
		facing_right = false
	
	# Set bow rotation
	bow_sprite.rotation = angle_radians
	
	# Position the bow slightly in front of the player in the direction of the mouse
	var bow_offset = Vector2(15, 0).rotated(angle_radians)  # Reduced from 20 to 15
	bow_sprite.position = Vector2(0, -10) + bow_offset
	
	# Flip the bow sprite vertically if aiming to the left
	bow_sprite.flip_v = !facing_right
	
	return angle_radians

func _physics_process(delta: float) -> void:
	if transitioning:
		return
		
	check_door_collision()

	if health_bar.value <= 0:
		game_over()
	
	# Ensure bow is visible when it's the selected weapon
	if Global.weapon == 'bow' and not bow_sprite.visible:
		bow_sprite.visible = true
		print("Forcing bow visibility in _physics_process")
	
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
		
		if Global.weapon != 'shield':
			shield_body.visible = false
			Global.has_shield = false
		else:
			shield_body.visible = true
			Global.has_shield = true

	if Input.is_action_just_pressed("switch"):
		weapon_counter += 1
		if weapon_counter > 3:
			weapon_counter = 0
		Global.weapon = weapons[weapon_counter]
	
	# Handle weapon switching with R key for bow
	if Input.is_action_just_pressed("bow_select"):
		print("Bow select key pressed")
		for i in range(weapons.size()):
			if weapons[i] == "bow":
				weapon_counter = i
				Global.weapon = "bow"
				
				# Force bow to be visible immediately
				bow_sprite.visible = true
				
				# Force update the bow position and rotation
				update_bow_position_and_rotation()
				
				print("Switched to bow via bow_select action - bow visibility: " + str(bow_sprite.visible))
				break
	
	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	if Global.weapon == 'sword':
		sprite_2d.animation = "sword"
	elif Global.weapon == 'bow':
		# Ensure bow sprite is visible
		bow_sprite.visible = true
		
		# Update bow position and rotation
		update_bow_position_and_rotation()
		
		# Debug print for bow position
		if Engine.get_process_frames() % 60 == 0:  # Print once per second at 60 FPS
			print("Bow position: " + str(bow_sprite.position) + ", rotation: " + str(bow_sprite.rotation))
	elif abs(velocity.x) > 1 and not Global.dead:
		sprite_2d.animation = "running"
	else:
		sprite_2d.animation = "default"
		
	if is_on_floor():
		can_double_jump = true
		recently_jumped = false
	
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite_2d.animation = "jumping"
	
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
		if Global.weapon == 'gun' and has_gun:
			progress_bar.value -= SHOOT_COST
			$Shoot.play()
			Global.shoot = [true, global_position, facing_right]
		elif Global.weapon == 'bow' and has_bow and progress_bar.value >= BOW_COST:
			progress_bar.value -= BOW_COST
			$Shoot.play()
			print("Shooting bow!")
			
			# Get the mouse position in global coordinates
			var mouse_pos = get_viewport().get_mouse_position()
			
			# Calculate direction from player to mouse
			var centered_position = global_position + Vector2(0, -10)
			var direction_to_mouse = (mouse_pos - centered_position).normalized()
			
			# Calculate angle for rotation
			var angle_radians = atan2(direction_to_mouse.y, direction_to_mouse.x)
			
			# Limit the angle based on which way the player is facing
			if facing_right:
				# If facing right, limit angle to right hemisphere (-90 to 90 degrees)
				angle_radians = clamp(angle_radians, -PI/2, PI/2)
			else:
				# If facing left, limit angle to left hemisphere (90 to 270 degrees)
				if angle_radians < 0:
					angle_radians = clamp(angle_radians, -PI, -PI/2)
				else:
					angle_radians = clamp(angle_radians, PI/2, PI)
			
			# Recalculate direction based on the limited angle
			var limited_direction = Vector2(cos(angle_radians), sin(angle_radians))
			
			# Calculate the arrow spawn position based on bow position and rotation
			var spawn_pos = global_position + bow_sprite.position
			
			# Pass the spawn position and direction for accurate aiming
			Global.shoot = [true, spawn_pos, spawn_pos + limited_direction * 1000]  # Point far in the direction
			
			print("Arrow fired from: " + str(spawn_pos) + " towards: " + str(spawn_pos + limited_direction * 1000))
		elif Global.weapon == 'sword':
			progress_bar.value -= SWORD_COST
			sprite_2d.animation = 'sword'
			var kill_radius: float = 70.0
			
			for node in get_parent().get_children():
				if node is Area2D and node.has_method("enemy_damage"):
					var direction = node.global_position - global_position
					var distance = direction.length()
					if distance < kill_radius:
						node.enemy_damage(50)

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
			
	get_right_direc(direction)
	
	Global.player_position = position

func switch_to_weapon(weapon_name: String) -> void:
	if weapons.has(weapon_name):
		Global.weapon = weapon_name
		
		# Update weapon_counter to match the selected weapon
		for i in range(weapons.size()):
			if weapons[i] == weapon_name:
				weapon_counter = i
				break
		
		# Show/hide bow sprite based on selected weapon
		if weapon_name == "bow":
			bow_sprite.visible = true
			# Force update the bow position and rotation immediately
			update_bow_position_and_rotation()
			print("Bow sprite should be visible now: " + str(bow_sprite.visible))
		else:
			bow_sprite.visible = false
		
		print("Switched to " + Global.weapon)

func check_door_collision():
	var door = get_node_or_null("../Door")
	if door:
		var distance = global_position.distance_to(door.global_position)
		if distance < 50:
			print("Player near door! Distance: " + str(distance))
			transition_to_level("res://Level2.tscn")

func transition_to_level(next_scene_path: String):
	if transitioning or fade_rect == null:
		return
		
	transitioning = true
	print("Starting transition to: " + next_scene_path)
	
	update_fade_rect_size()
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	
	print("Fade completed, changing scene")
	get_tree().change_scene_to_file(next_scene_path)

func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

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
	# Ensure bow stays visible when it's the selected weapon
	if Global.weapon == 'bow':
		if not bow_sprite.visible:
			bow_sprite.visible = true
			print("Ensuring bow remains visible in _process - was hidden")
			
			# Force update the bow position and rotation
			update_bow_position_and_rotation()
	else:
		if bow_sprite.visible:
			bow_sprite.visible = false
			print("Hiding bow in _process as weapon is: " + Global.weapon)
	
	# Debug print every few seconds
	if Engine.get_process_frames() % 60 == 0:  # Print once per second at 60 FPS
		print("Current weapon: " + Global.weapon + ", Bow visible: " + str(bow_sprite.visible) + ", Weapon counter: " + str(weapon_counter)) 