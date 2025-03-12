extends CharacterBody2D

# Add a signal for weapon changes
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

# Charged attack constants
const MAX_CHARGE_TIME := 1.5  # Maximum charge time in seconds
const MIN_CHARGE_TIME := 0.2  # Minimum time to start charging
const CHARGE_SWORD_RADIUS_MULTIPLIER := 1.5  # How much larger the sword radius gets when fully charged
const CHARGE_SWORD_DAMAGE_MULTIPLIER := 2.0  # How much more damage the sword does when fully charged
const CHARGE_BOW_SPEED_MULTIPLIER := 2.0  # How much faster the arrow flies when fully charged
const CHARGE_BOW_DAMAGE_MULTIPLIER := 2.0  # How much more damage the bow does when fully charged

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var bow_sprite = null
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
# Add a variable to track the current weapon locally
var current_weapon = "bow"
# Add a cooldown for weapon switching to prevent rapid switches
var weapon_switch_cooldown = 0.0
var last_weapon_switch_time = 0.0

# Charged attack variables
var is_charging := false
var charge_start_time := 0.0
var current_charge := 0.0
var charge_effect = null

func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	
	var parent = get_parent()
	shield_body = parent.get_node_or_null("shield")
	if shield_body != null:
		shield_body.visible = false

	# COMPLETELY RECREATE THE BOW SPRITE EVERY TIME
	# Remove any existing bow sprite
	if has_node("BowSprite"):
		$BowSprite.queue_free()
		
	# Create a new bow sprite
	var bow_texture = preload("res://assets/bow.png")
	bow_sprite = Sprite2D.new()
	bow_sprite.name = "BowSprite"
	bow_sprite.texture = bow_texture
	bow_sprite.scale = Vector2(0.75, 0.75)  # Made bow much smaller
	add_child(bow_sprite)
	
	# Create charge effect
	setup_charge_effect()

	# Start with bow as the default weapon
	current_weapon = "bow"
	Global.weapon = "bow"
	weapon_counter = weapons.find("bow")
	
	# Connect our own signal
	weapon_changed.connect(_on_weapon_changed)
	
	setup_transition_layer()
	
	# Force bow to be visible at start
	bow_sprite.visible = true
	update_bow_position_and_rotation()

# Setup charge effect visual
func setup_charge_effect():
	charge_effect = ColorRect.new()
	charge_effect.name = "ChargeEffect"
	charge_effect.color = Color(1, 0.5, 0, 0.0)  # Orange with 0 alpha initially
	charge_effect.size = Vector2(40, 40)
	charge_effect.position = Vector2(-20, -20)
	charge_effect.visible = false
	add_child(charge_effect)

# Add a function to handle weapon changes
func _on_weapon_changed(new_weapon):
	current_weapon = new_weapon
	Global.weapon = new_weapon
	
	# Handle bow visibility immediately
	if new_weapon == "bow":
		if not bow_sprite or not is_instance_valid(bow_sprite):
			var bow_texture = preload("res://assets/bow.png")
			bow_sprite = Sprite2D.new()
			bow_sprite.name = "BowSprite"
			bow_sprite.texture = bow_texture
			bow_sprite.scale = Vector2(0.75, 0.75)
			add_child(bow_sprite)
		
		bow_sprite.visible = true
		update_bow_position_and_rotation()
		
		# Ensure the bow animation is set
		sprite_2d.animation = "bow"
	elif bow_sprite and is_instance_valid(bow_sprite):
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
	# Check if we're in weapon switch cooldown
	if Time.get_ticks_msec() - last_weapon_switch_time < 300:  # 300ms cooldown
		return
		
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Q:
				# Force sword selection
				print("Q pressed - switching to sword")
				weapon_counter = weapons.find("sword")
				switch_to_weapon("sword")
				# Force sword animation immediately
				sprite_2d.animation = "sword"
				# Ensure shield is hidden
				if shield_body != null:
					shield_body.visible = false
					Global.has_shield = false
				# Set cooldown
				last_weapon_switch_time = Time.get_ticks_msec()
			elif event.keycode == KEY_R:
				# Force bow selection
				weapon_counter = weapons.find("bow")
				switch_to_weapon("bow")
				# Force immediate update after switching to bow
				if bow_sprite and is_instance_valid(bow_sprite):
					bow_sprite.visible = true
					update_bow_position_and_rotation()
				# Set cooldown
				last_weapon_switch_time = Time.get_ticks_msec()
			elif event.keycode == KEY_C:
				# Force shield selection
				weapon_counter = weapons.find("shield")
				switch_to_weapon("shield")
				# Ensure shield is visible
				if shield_body != null:
					shield_body.visible = true
					Global.has_shield = true
				# Set cooldown
				last_weapon_switch_time = Time.get_ticks_msec()

func update_bow_position_and_rotation():
	if not bow_sprite or not is_instance_valid(bow_sprite):
		return 0
		
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
	var bow_offset = Vector2(15, 0).rotated(angle_radians)
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
	
	# Check if Global.weapon has been changed externally and fix it
	if Global.weapon != current_weapon:
		Global.weapon = current_weapon
	
	# ALWAYS check bow state when bow is the active weapon
	if current_weapon == "bow":
		# Recreate bow sprite if it's missing or invalid
		if not bow_sprite or not is_instance_valid(bow_sprite):
			var bow_texture = preload("res://assets/bow.png")
			bow_sprite = Sprite2D.new()
			bow_sprite.name = "BowSprite"
			bow_sprite.texture = bow_texture
			bow_sprite.scale = Vector2(0.75, 0.75)
			add_child(bow_sprite)
		
		# Ensure bow is visible and update its position
		bow_sprite.visible = true
		update_bow_position_and_rotation()
		
		# Force bow animation to be visible
		sprite_2d.animation = "bow"
		sprite_2d.visible = true
	elif bow_sprite and is_instance_valid(bow_sprite):
		# Hide bow when not using it
		bow_sprite.visible = false
	
	# Handle charging
	if is_charging:
		var charge_time = Time.get_ticks_msec() / 1000.0 - charge_start_time
		current_charge = clamp(charge_time, 0, MAX_CHARGE_TIME)
		
		# Update charge effect
		if charge_effect:
			# Scale the alpha from 0 to 0.5 based on charge
			var charge_percent = (current_charge - MIN_CHARGE_TIME) / (MAX_CHARGE_TIME - MIN_CHARGE_TIME)
			if charge_percent > 0:
				charge_effect.visible = true
				charge_effect.color.a = charge_percent * 0.5
				
				# Scale the effect size based on charge
				var scale_factor = 1.0 + charge_percent
				charge_effect.size = Vector2(40, 40) * scale_factor
				charge_effect.position = Vector2(-20, -20) * scale_factor
				
				# Change color based on weapon
				if current_weapon == "sword":
					charge_effect.color = Color(1, 0.5, 0, charge_effect.color.a)  # Orange for sword
				elif current_weapon == "bow":
					charge_effect.color = Color(0, 0.7, 1, charge_effect.color.a)  # Blue for bow
			else:
				charge_effect.visible = false
	
	if shield_body != null:
		# Always update shield position for smooth transitions
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
		
		# Make sure shield is only visible when shield is the current weapon
		# This is the critical part - ensure shield is hidden when using sword
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
	
	# IMPORTANT: Set animation AFTER handling bow visibility
	# This prevents animation changes from hiding the bow
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite_2d.animation = "jumping"
	elif current_weapon == 'sword':
		sprite_2d.animation = "sword"
	elif current_weapon == 'bow':
		sprite_2d.animation = "bow"
	elif abs(velocity.x) > 1 and not Global.dead:
		sprite_2d.animation = "running"
	else:
		sprite_2d.animation = "default"
		
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
	
	# Start charging when space is pressed
	if Input.is_action_just_pressed("ui_select"):
		# Only play sword animation when sword is equipped
		if current_weapon == 'sword':
			sprite_2d.animation = 'sword'
			sprite_2d.frame = 0  # Reset animation to first frame
		
		# Start charging
		is_charging = true
		charge_start_time = Time.get_ticks_msec() / 1000.0
		current_charge = 0.0
	
	# Release charge when space is released
	if Input.is_action_just_released("ui_select"):
		# Calculate charge percentage (0 to 1)
		var charge_time = current_charge
		var is_charged = charge_time >= MIN_CHARGE_TIME
		var charge_percent = 0.0
		
		if is_charged:
			charge_percent = (charge_time - MIN_CHARGE_TIME) / (MAX_CHARGE_TIME - MIN_CHARGE_TIME)
			charge_percent = clamp(charge_percent, 0.0, 1.0)
		
		# Hide charge effect
		if charge_effect:
			charge_effect.visible = false
		
		if current_weapon == 'gun' and has_gun:
			progress_bar.value -= SHOOT_COST
			$Shoot.play()
			Global.shoot = [true, global_position, facing_right]
		elif current_weapon == 'bow' and has_bow and progress_bar.value >= BOW_COST:
			progress_bar.value -= BOW_COST
			$Shoot.play()
			
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
			
			# Apply charge multiplier to arrow speed if charged
			var speed_multiplier = 1.0
			var damage_multiplier = 1.0
			if is_charged:
				speed_multiplier = 1.0 + charge_percent * (CHARGE_BOW_SPEED_MULTIPLIER - 1.0)
				damage_multiplier = 1.0 + charge_percent * (CHARGE_BOW_DAMAGE_MULTIPLIER - 1.0)
				print("Charged bow shot! Speed: " + str(speed_multiplier) + "x, Damage: " + str(damage_multiplier) + "x")
			
			if bow_sprite and is_instance_valid(bow_sprite):
				# Calculate the arrow spawn position based on bow position and rotation
				var spawn_pos = global_position + bow_sprite.position
				
				# Pass the spawn position and direction for accurate aiming
				# Add speed and damage multipliers to the shoot data
				Global.shoot = [true, spawn_pos, spawn_pos + limited_direction * 1000 * speed_multiplier, damage_multiplier]
			else:
				# Fallback if bow sprite is missing
				Global.shoot = [true, global_position + Vector2(0, -10), global_position + Vector2(0, -10) + limited_direction * 1000 * speed_multiplier, damage_multiplier]

		elif current_weapon == 'sword':
			progress_bar.value -= SWORD_COST
			# Force sword animation
			sprite_2d.animation = "sword"
			sprite_2d.frame = 0  # Reset animation to first frame
			
			var kill_radius: float = 70.0
			var damage: float = 50.0
			
			# Apply charge multiplier to sword radius and damage if charged
			if is_charged:
				var radius_multiplier = 1.0 + charge_percent * (CHARGE_SWORD_RADIUS_MULTIPLIER - 1.0)
				var damage_multiplier = 1.0 + charge_percent * (CHARGE_SWORD_DAMAGE_MULTIPLIER - 1.0)
				kill_radius *= radius_multiplier
				damage *= damage_multiplier
				print("Charged sword attack! Radius: " + str(radius_multiplier) + "x, Damage: " + str(damage_multiplier) + "x")
				
				# Visual feedback for charged sword attack
				var sword_slash = ColorRect.new()
				sword_slash.color = Color(1, 0.5, 0, 0.3)  # Semi-transparent orange
				sword_slash.size = Vector2(kill_radius * 2, kill_radius * 2)
				sword_slash.position = Vector2(-kill_radius, -kill_radius)
				add_child(sword_slash)
				
				# Animate the slash effect
				var tween = create_tween()
				tween.tween_property(sword_slash, "color:a", 0.0, 0.3)
				tween.tween_callback(sword_slash.queue_free)
			
			for node in get_parent().get_children():
				if node is Area2D and node.has_method("enemy_damage"):
					var direction = node.global_position - global_position
					var distance = direction.length()
					if distance < kill_radius:
						node.enemy_damage(damage)
			
			# Force the sword animation to play from the beginning
			sprite_2d.play("sword")
			sprite_2d.frame = 0  # Ensure we start from the first frame
		
		# Reset charging state
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
			
	get_right_direc(direction)
	
	Global.player_position = position

func switch_to_weapon(weapon_name: String) -> void:
	if weapons.has(weapon_name):
		print("Switching to weapon: " + weapon_name + " (index: " + str(weapons.find(weapon_name)) + ")")
		
		# Update weapon state using our signal
		weapon_changed.emit(weapon_name)
		weapon_counter = weapons.find(weapon_name)
		
		# Handle bow
		if weapon_name == "bow":
			# Check if bow sprite exists and is valid, recreate if needed
			if not bow_sprite or not is_instance_valid(bow_sprite):
				var bow_texture = preload("res://assets/bow.png")
				bow_sprite = Sprite2D.new()
				bow_sprite.name = "BowSprite"
				bow_sprite.texture = bow_texture
				bow_sprite.scale = Vector2(0.75, 0.75)
				add_child(bow_sprite)
			
			# Force bow to be visible and update its position
			bow_sprite.visible = true
			update_bow_position_and_rotation()
		elif weapon_name == "sword":
			# Force sword animation
			sprite_2d.animation = "sword"
			# Ensure shield is hidden
			if shield_body != null:
				shield_body.visible = false
				Global.has_shield = false
			print("Sword equipped - shield visibility: " + str(shield_body.visible if shield_body != null else "no shield"))
		elif weapon_name == "shield":
			# Ensure shield is visible
			if shield_body != null:
				shield_body.visible = true
				Global.has_shield = true
			print("Shield equipped - shield visibility: " + str(shield_body.visible if shield_body != null else "no shield"))
		else:
			# Hide bow sprite when not using bow
			if bow_sprite and is_instance_valid(bow_sprite):
				bow_sprite.visible = false

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
	# Check if Global.weapon has been changed externally and fix it
	if Global.weapon != current_weapon:
		Global.weapon = current_weapon
	
	# Only update bow in process if it's the active weapon
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
