extends CharacterBody2D

signal area_entered(area)

var DISTANCE_GRAPPLE: int
var GRAPPLE_POS: Vector2
const SPEED = 250.0
const JUMP_VELOCITY = -350.0
const ACCELERATION = 3500.0
const FRICTION = 2000.0
const SWING_BOOST = 1.5
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
var facing_right := true
var coyote := true
var jumping := false
var double_jump_available := true
var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0
var can_change_ani := true
var coins := 0
var vine_cooldown := 0.0
var vine_cooldown_time := 0.8
var vine_energy := 100.0
var vine_energy_max := 100.0
var vine_energy_regen := 10.0
var vine_swing_cost := 20.0
var special_ability_active := false
var special_ability_cooldown := 0.0
var special_ability_cooldown_time := 5.0
var damage_number_scene = preload("res://damage_number.tscn")
var current_weapon = "vine"
var weapons = ["vine"]
var weapon_counter := 0
var attack_range := 200.0  # Limited attack range
var attack_cooldown := 0.0
var attack_cooldown_time := 0.5
var attack_damage := 25

# Multipliers for special ability
var speed_multiplier = 1.0
var jump_multiplier = 1.0
var rope_length_multiplier = 1.0
var acceleration_multiplier = 1.0
var friction_multiplier = 1.0

func _ready() -> void:
	# Add to player group
	add_to_group("player")
	
	# Set collision settings
	collision_layer = 8  # Player layer
	collision_mask = 15  # Collide with environment, enemies, and bullets
	
	# Setup UI
	if progress_bar:
		progress_bar.max_value = vine_energy_max
		progress_bar.value = vine_energy
	
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = 100
	
	# Initialize global variables
	Global.player_position = position
	Global.has_shield = false
	Global.weapon = "vine"  # Set Tarzan's default weapon
	
	# Set up special ability indicator
	setup_special_ability_indicator()
	
	# Connect area_entered signal for door interaction
	connect("area_entered", _on_area_entered)
	
	# Connect body_entered signal for enemy collision
	connect("body_entered", _on_body_entered)
	
	# Hide the HotkeyLabel that appears above the player
	var hotkey_label = get_node_or_null("HotkeyLabel")
	if hotkey_label:
		hotkey_label.visible = false

func setup_special_ability_indicator():
	# Remove any existing indicator above the player
	var old_indicator = get_node_or_null("SpecialAbilityIndicator")
	if old_indicator:
		old_indicator.queue_free()
	
	# Get the hotbar from the UI
	var hotbar = get_node_or_null("../CanvasLayer/hotbar")
	if not hotbar:
		print("Hotbar not found in UI")
		return
	
	# Modify the hotbar for Tarzan-specific weapons
	var grid_container = hotbar.get_node_or_null("GridContainer")
	if grid_container:
		# Modify first button (Q) for Tarzan's vine weapon
		var button1 = grid_container.get_node_or_null("Button")
		var label1 = grid_container.get_node_or_null("Button/RichTextLabel")
		if button1 and label1:
			button1.icon = load("res://assets/yellowNinja - idle.png") if ResourceLoader.exists("res://assets/yellowNinja - idle.png") else null
			label1.text = "  Q"
		
		# Modify second button (R) for Tarzan's special ability
		var button2 = grid_container.get_node_or_null("Button2")
		var label2 = grid_container.get_node_or_null("Button2/RichTextLabel2")
		if button2 and label2:
			# Create a special ability indicator in the second button
			var special_indicator = ColorRect.new()
			special_indicator.name = "SpecialAbilityIndicator"
			special_indicator.color = Color(0.0, 0.8, 0.2, 0.5)
			special_indicator.size = Vector2(60, 60)  # Enlarged from 40x40 to 60x60
			special_indicator.position = Vector2(0, 10)  # Moved down by 10 pixels
			
			# Add a label to show "F" key
			var f_label = Label.new()
			f_label.name = "FKeyLabel"
			f_label.text = "F"
			f_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			f_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			f_label.size = Vector2(60, 60)  # Match parent size
			f_label.add_theme_font_size_override("font_size", 20)  # Larger font
			
			# Remove any existing children
			for child in button2.get_children():
				if child != label2:
					child.queue_free()
			
			# Add the indicator and label to the button
			button2.add_child(special_indicator)
			special_indicator.add_child(f_label)
			
			# Update the button label
			label2.text = "   F"
			label2.position.y += 10  # Move the label down as well
		
		# Hide the third button (C) as Tarzan doesn't use it
		var button3 = grid_container.get_node_or_null("Button3")
		if button3:
			button3.visible = false
	
	print("Tarzan-specific hotbar setup complete with enlarged cooldown box")

func coyote_change():
	await get_tree().create_timer(0.5).timeout
	coyote = false

func _process(delta: float) -> void:
	# Update global player position
	Global.player_position = position
	
	# Debug F key press
	if Input.is_key_pressed(KEY_F):
		print("F key pressed directly")
		if special_ability_cooldown <= 0 and vine_energy >= 50 and not special_ability_active:
			print("Activating special ability via direct F key press")
			activate_special_ability()
	
	if Input.is_action_just_pressed("ui_focus_next"):
		print("ui_focus_next action triggered")
		print("Special ability cooldown: " + str(special_ability_cooldown))
		print("Vine energy: " + str(vine_energy))
		if special_ability_cooldown <= 0 and vine_energy >= 50 and not special_ability_active:
			print("Activating special ability via ui_focus_next action")
			activate_special_ability()
	
	# Handle movement states
	if is_on_floor():
		coyote = true
		jumping = false
		double_jump_available = true
	else:
		coyote_change()
		jump_catch()
	
	if not is_on_floor():
		head_catch()
	
	# Check health
	if health_bar and health_bar.value <= 0:
		game_over()
	
	# Handle vine energy regeneration
	if progress_bar:
		if vine_energy < vine_energy_max and not hooked and not is_grappling:
			vine_energy = min(vine_energy + vine_energy_regen * delta, vine_energy_max)
			progress_bar.value = vine_energy
	
	# Handle vine swing release
	if Input.is_action_just_released("start") and hooked: 
		release_vine_with_boost()
	
	# Handle vine swing initiation
	if Input.is_action_just_pressed("start") and vine_energy >= vine_swing_cost and vine_cooldown <= 0:
		initiate_vine_swing()
	
	# Update cooldowns
	vine_cooldown = max(0, vine_cooldown - delta)
	special_ability_cooldown = max(0, special_ability_cooldown - delta)
	attack_cooldown = max(0, attack_cooldown - delta)
	
	# Update UI elements
	update_special_ability_indicator()
	
	# Handle movement based on state
	if not Global.dead:
		if is_grappling:
			handle_grappling_movement(delta)
		elif hooked:
			handle_vine_swing(delta)
			queue_redraw() 
		else:
			handle_normal_movement(delta)
	
	# Update sprite direction
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0
		facing_right = velocity.x > 0
	
	# Update animations
	update_animations()
	
	# Draw rope/vine
	queue_redraw()

func handle_normal_movement(delta: float) -> void:
	# Jump handling
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor() or coyote:
			velocity.y = JUMP_VELOCITY * jump_multiplier
			jumping = true
		elif double_jump_available and vine_energy >= 20:
			velocity.y = JUMP_VELOCITY * 0.9 * jump_multiplier
			double_jump_available = false
			vine_energy -= 20
			var progress_bar = get_node_or_null("../CanvasLayer/JumpBar")
			if progress_bar:
				progress_bar.value = vine_energy
	
	if Input.is_action_just_released('ui_up') and jumping:
		velocity.y = max(velocity.y, JUMP_VELOCITY * 0.5 * jump_multiplier)
		jumping = false
	
	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * friction_multiplier * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED * speed_multiplier, ACCELERATION * acceleration_multiplier * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * friction_multiplier * delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	move_and_slide()

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
		draw_line(Vector2(0, -16), to_local(GRAPPLE_POS), Color(0.35, 0.7, 0.9), 3, true)
	elif is_grappling:
		draw_line(Vector2(0, -16), to_local(current_grappling_point), Color(0.35, 0.7, 0.9), 3, true)

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

func player_damage(damage_amount):
	print("Tarzan taking damage: " + str(damage_amount))
	
	# Skip if already invulnerable
	if is_invulnerable:
		print("Tarzan is invulnerable, ignoring damage")
		return
	
	# Apply damage to health bar
	if health_bar:
		health_bar.value -= damage_amount
		print("Health reduced to: " + str(health_bar.value))
	else:
		print("Health bar not found!")
	
	# Visual feedback
	$Sprite2D.animation = "hit"
	$Sprite2D.frame = 0
	
	# Make player invulnerable temporarily
	is_invulnerable = true
	
	# Flash effect
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 0.7), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 0.7), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1), 0.1)
	
	# End invulnerability after a delay
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false
	print("Invulnerability ended")

func coin_collected(num):
	coins += num
	Global.coins_collected = coins
	$"+1".visible = true
	$collect.start()

func jump_catch():
	if ($catch_jump/right.is_colliding() or $catch_jump/left.is_colliding()) and jumping:
		position.y -= 3
		
func head_catch():
	if $"catch head/left_stop".is_colliding() and not $"catch head/left_stop".is_colliding():
		position.x -= 30
	elif $"catch head/right_stop".is_colliding() and not $"catch head/right_go".is_colliding():
		position.x += 30
		

func _on_collect_timeout() -> void:
	$"+1".visible = false

func release_vine_with_boost():
	hooked = false
	
	if motion.length() > 50:
		velocity = motion * SWING_BOOST
	else:
		velocity = motion
	
	vine_cooldown = vine_cooldown_time
	$"extra+damage".start()

func initiate_vine_swing():
	mouse_pos = get_global_mouse_position()
	var dir_to_grapple = global_position.direction_to(mouse_pos)
	
	# Set up raycast
	$grapple.target_position = dir_to_grapple * rope_length * rope_length_multiplier
	$grapple.force_raycast_update()
	
	if $grapple.is_colliding():
		# Successful vine attachment
		GRAPPLE_POS = $grapple.get_collision_point()
		DISTANCE_GRAPPLE = global_position.distance_to(GRAPPLE_POS)
		current_rope_length = DISTANCE_GRAPPLE  
		hooked = true
		was_hooked = true
		motion = velocity
		
		# Use vine energy
		vine_energy -= vine_swing_cost
		var progress_bar = get_node_or_null("../CanvasLayer/JumpBar")
		if progress_bar:
			progress_bar.value = vine_energy
		
		# Play sound effect
		play_vine_sound()
		
		# Start trail effect
		create_swing_trail()

func activate_special_ability():
	# Don't activate if already active or not enough energy
	if special_ability_active or vine_energy < 50:
		return
		
	special_ability_active = true
	vine_energy -= 50
	
	# Update UI
	var progress_bar = get_node_or_null("../CanvasLayer/JumpBar")
	if progress_bar:
		progress_bar.value = vine_energy
	
	# Create visual effects
	create_special_ability_effects()
	
	# Play sound effect
	play_special_ability_sound()
	
	# Apply movement enhancements using multipliers
	speed_multiplier = 1.5
	jump_multiplier = 1.2
	rope_length_multiplier = 1.5
	acceleration_multiplier = 1.5
	friction_multiplier = 0.8  # Less friction for smoother movement
	
	# Apply temporary invulnerability
	is_invulnerable = true
	
	# Reset after duration
	await get_tree().create_timer(3.0).timeout
	
	# Remove enhancements
	speed_multiplier = 1.0
	jump_multiplier = 1.0
	rope_length_multiplier = 1.0
	acceleration_multiplier = 1.0
	friction_multiplier = 1.0
	
	# End ability
	special_ability_active = false
	special_ability_cooldown = special_ability_cooldown_time
	
	# End invulnerability after a short grace period
	await get_tree().create_timer(0.5).timeout
	is_invulnerable = false

func update_special_ability_indicator():
	# Get the indicator from the hotbar
	var hotbar = get_node_or_null("../CanvasLayer/hotbar")
	if not hotbar:
		return
		
	var grid_container = hotbar.get_node_or_null("GridContainer")
	if not grid_container:
		return
		
	var button2 = grid_container.get_node_or_null("Button2")
	if not button2:
		return
		
	var indicator = button2.get_node_or_null("SpecialAbilityIndicator")
	if indicator:
		# Ensure correct size and position
		indicator.size = Vector2(60, 60)
		indicator.position = Vector2(0, 10)
		
		if special_ability_cooldown <= 0 and vine_energy >= 50:
			indicator.visible = true
			indicator.color = Color(0.0, 0.8, 0.2, 0.5)
			
			# Add a pulsing effect when ready
			var tween = create_tween()
			tween.tween_property(indicator, "color:a", 0.8, 0.5)
			tween.tween_property(indicator, "color:a", 0.5, 0.5)
			tween.set_loops()
			
		elif special_ability_active:
			indicator.visible = true
			indicator.color = Color(0.0, 0.8, 0.2, 0.8)
		else:
			# Show cooldown timer
			if special_ability_cooldown > 0:
				indicator.visible = true
				indicator.color = Color(0.5, 0.5, 0.5, 0.5)
				
				# Update the label to show cooldown
				var label = indicator.get_node_or_null("FKeyLabel")
				if label:
					label.text = str(int(special_ability_cooldown))
					label.size = Vector2(60, 60)
					label.add_theme_font_size_override("font_size", 20)
			else:
				indicator.visible = false

func update_animations() -> void:
	if $Sprite2D.animation != 'die' and $Sprite2D.animation != 'hit':
		if hooked or is_grappling:
			$Sprite2D.animation = 'attack'
		elif not is_on_floor():
			$Sprite2D.animation = 'idle'
		elif abs(velocity.x) > 1:
			$Sprite2D.animation = 'run'
		else:
			$Sprite2D.animation = 'idle'

# Door interaction function
func _on_area_entered(area):
	print("Area entered: " + area.name)
	if area.name == "Door" or area.name.begins_with("Door"):
		print("Door detected! Changing scene to level2")
		# Directly change to level2 scene
		get_tree().change_scene_to_file("res://level2.tscn")
	elif area.is_in_group("enemies") and not is_invulnerable:
		player_damage(10)  # Take damage from enemy contact

# Damage number spawning for attacks
func spawn_damage_number(hit_position, damage_amount, is_critical=false):
	var damage_instance = damage_number_scene.instantiate()
	damage_instance.position = hit_position + Vector2(0, -20)
	
	# Make sure the damage number has the required methods
	if damage_instance.has_method("set_damage_value"):
		damage_instance.set_damage_value(damage_amount)
	
	if damage_instance.has_method("set_critical"):
		damage_instance.set_critical(is_critical)
	
	get_parent().add_child(damage_instance)

func _physics_process(delta: float) -> void:
	# Update global player position
	Global.player_position = position
	
	# Check for collisions with enemies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		print("Collision detected with: " + str(collider.name))
		
		# Check for enemy collisions
		if collider.is_in_group("enemies") or "enemy" in collider.name.to_lower():
			print("Enemy collision detected!")
			if not is_invulnerable:
				player_damage(10)
				break
		
		# Check for door collisions
		if collider.name == "Door" or collider.name.begins_with("Door"):
			print("Door collision detected! Attempting to change scene")
			get_tree().change_scene_to_file("res://level2.tscn")
	
	# Handle movement based on state
	if not Global.dead:
		if is_grappling:
			handle_grappling_movement(delta)
		elif hooked:
			handle_vine_swing(delta)
			queue_redraw() 
		else:
			handle_normal_movement(delta)
	
	# Update sprite direction
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0
		facing_right = velocity.x > 0
	
	# Update animations
	update_animations()
	
	# Draw rope/vine
	queue_redraw()

func handle_vine_swing(delta: float) -> void:
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
	
	# Adjust sound based on swing speed
	if motion.length() > 50:
		play_vine_sound()
	
	# Check for enemies in the swing path - apply damage more frequently
	# Always check for enemies when swinging, regardless of speed
	print("Swing speed: " + str(motion.length()) + " - Checking for enemies")
	apply_vine_damage()
	
	# Visual feedback for swinging
	create_swing_trail()

func handle_grappling_movement(delta: float) -> void:
	current_rope_length = global_position.distance_to(current_grappling_point)
	swing_grapple(delta)
	
	var dir_to_grappling = global_position.direction_to(current_grappling_point)
	velocity = dir_to_grappling * grapple_speed
	
	if global_position.distance_to(current_grappling_point) < 50 or previous_pos == position:
		is_grappling = false
	
	previous_pos = position

func create_special_ability_effects():
	# Create a particle effect for the special ability
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
	glow.texture = load("res://icon.svg") if ResourceLoader.exists("res://icon.svg") else null
	glow.color = Color(0.0, 0.8, 0.2, 0.5)
	glow.energy = 0.8
	glow.texture_scale = 2.0
	add_child(glow)
	
	# Create a tween to fade out the glow
	var glow_tween = create_tween()
	glow_tween.tween_property(glow, "energy", 0.0, 3.0)
	glow_tween.tween_callback(glow.queue_free)

func play_vine_sound():
	var sound = get_node_or_null("VineSound")
	if sound and sound is AudioStreamPlayer:
		# Adjust pitch based on swing speed
		var speed_factor = clamp(motion.length() / 500.0, 0.8, 1.5)
		sound.pitch_scale = speed_factor
		
		if not sound.playing:
			sound.play()
			
func play_special_ability_sound():
	var sound = get_node_or_null("VineSound")
	if sound and sound is AudioStreamPlayer:
		sound.pitch_scale = 0.7
		sound.volume_db = 0.0
		sound.play()
		
		# Reset volume after playing
		var tween = create_tween()
		tween.tween_interval(0.5)
		tween.tween_property(sound, "volume_db", -5.0, 0.5)

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

func apply_vine_damage():
	print("Checking for enemies to damage with vine swing")
	
	# Check for enemies in the swing path using a ray query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, GRAPPLE_POS)
	query.collision_mask = 4  # Enemy collision layer
	var result = space_state.intersect_ray(query)
	
	var enemy_hit = false
	
	if result:
		print("Ray hit: " + str(result.collider.name) + " - Class: " + str(result.collider.get_class()))
		if result.collider.is_in_group("enemies") or "enemy" in result.collider.name.to_lower():
			enemy_hit = true
			var enemy = result.collider
			print("Enemy hit by vine: " + enemy.name)
			var damage = 15
			var is_critical = was_hooked and special_ability_active
			
			if is_critical:
				damage *= 2
			
			print("Applying " + str(damage) + " damage to enemy")
			
			# Try multiple damage methods to ensure compatibility
			if enemy.has_method("enemy_damage"):
				enemy.enemy_damage(damage)
				spawn_damage_number(enemy.global_position, damage, is_critical)
			elif enemy.has_method("take_damage"):
				enemy.take_damage()
				spawn_damage_number(enemy.global_position, damage, is_critical)
				
			# Visual feedback
			var impact_effect = ColorRect.new()
			impact_effect.color = Color(1.0, 0.7, 0.2, 0.7)
			impact_effect.size = Vector2(30, 30)
			impact_effect.position = Vector2(-15, -15)
			enemy.add_child(impact_effect)
			
			var tween = create_tween()
			tween.tween_property(impact_effect, "color:a", 0.0, 0.3)
			tween.tween_callback(impact_effect.queue_free)
	
	# If ray didn't hit, try a wider area check
	if not enemy_hit:
		print("Ray didn't hit enemy, trying area check")
		var shape_query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 100  # Increased detection radius
		shape_query.set_shape(circle_shape)
		shape_query.transform = Transform2D(0, global_position)
		shape_query.collision_mask = 4  # Enemy collision layer
		
		var shape_results = space_state.intersect_shape(shape_query)
		print("Area check found " + str(shape_results.size()) + " potential enemies")
		
		for shape_result in shape_results:
			var collider = shape_result.collider
			print("Area check found: " + str(collider.name) + " - Class: " + str(collider.get_class()))
			
			if collider.is_in_group("enemies") or "enemy" in collider.name.to_lower():
				var enemy = collider
				print("Enemy hit by vine area: " + enemy.name)
				var damage = 15
				var is_critical = was_hooked and special_ability_active
				
				if is_critical:
					damage *= 2
				
				print("Applying " + str(damage) + " damage to enemy via area check")
				
				# Try multiple damage methods to ensure compatibility
				if enemy.has_method("enemy_damage"):
					enemy.enemy_damage(damage)
					spawn_damage_number(enemy.global_position, damage, is_critical)
				elif enemy.has_method("take_damage"):
					enemy.take_damage()
					spawn_damage_number(enemy.global_position, damage, is_critical)
					
				# Visual feedback
				var impact_effect = ColorRect.new()
				impact_effect.color = Color(1.0, 0.7, 0.2, 0.7)
				impact_effect.size = Vector2(30, 30)
				impact_effect.position = Vector2(-15, -15)
				enemy.add_child(impact_effect)
				
				var tween = create_tween()
				tween.tween_property(impact_effect, "color:a", 0.0, 0.3)
				tween.tween_callback(impact_effect.queue_free)
				break  # Only hit one enemy per swing
	
	# Also check for direct collisions with enemies
	var direct_query = PhysicsShapeQueryParameters2D.new()
	var direct_shape = CircleShape2D.new()
	direct_shape.radius = 30  # Close range detection
	direct_query.set_shape(direct_shape)
	direct_query.transform = Transform2D(0, global_position)
	direct_query.collision_mask = 4  # Enemy collision layer
	
	var direct_results = space_state.intersect_shape(direct_query)
	for direct_result in direct_results:
		var collider = direct_result.collider
		if collider.is_in_group("enemies") or "enemy" in collider.name.to_lower():
			var enemy = collider
			print("Enemy hit by direct contact: " + enemy.name)
			var damage = 15
			var is_critical = was_hooked and special_ability_active
			
			if is_critical:
				damage *= 2
			
			print("Applying " + str(damage) + " damage to enemy via direct contact")
			
			# Try multiple damage methods to ensure compatibility
			if enemy.has_method("enemy_damage"):
				enemy.enemy_damage(damage)
				spawn_damage_number(enemy.global_position, damage, is_critical)
			elif enemy.has_method("take_damage"):
				enemy.take_damage()
				spawn_damage_number(enemy.global_position, damage, is_critical)
				
			# Visual feedback
			var impact_effect = ColorRect.new()
			impact_effect.color = Color(1.0, 0.7, 0.2, 0.7)
			impact_effect.size = Vector2(30, 30)
			impact_effect.position = Vector2(-15, -15)
			enemy.add_child(impact_effect)
			
			var tween = create_tween()
			tween.tween_property(impact_effect, "color:a", 0.0, 0.3)
			tween.tween_callback(impact_effect.queue_free)
			break  # Only hit one enemy per direct check

func _input(event):
	# Check for attack inputs with more debug info
	if event.is_action_pressed("ui_select") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		print("Attack triggered! Event type: " + str(event.get_class()))
		perform_vine_attack()

func perform_vine_attack():
	print("Performing vine attack")
	
	# Check cooldown
	if attack_cooldown > 0:
		print("Attack on cooldown: " + str(attack_cooldown) + " seconds remaining")
		return
	
	# Check if enough energy
	var attack_energy_cost = 10.0  # Energy cost for each attack
	if vine_energy < attack_energy_cost:
		print("Not enough energy to attack! Current energy: " + str(vine_energy))
		return
		
	# Consume energy
	vine_energy -= attack_energy_cost
	if progress_bar:
		progress_bar.value = vine_energy
		print("Energy reduced to: " + str(vine_energy))
		
	# Set cooldown
	attack_cooldown = attack_cooldown_time
	
	# Get mouse position for targeting
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Calculate attack range with limited distance
	var attack_endpoint = global_position + direction * attack_range
	
	# Visual feedback for attack - thicker line for better visibility
	var line = Line2D.new()
	line.width = 8.0
	line.default_color = Color(0.2, 0.8, 0.2, 0.8)
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(attack_endpoint))
	add_child(line)
	
	# Animate the attack with a whip-like effect
	var tween = create_tween()
	tween.tween_property(line, "width", 3.0, 0.2)
	tween.parallel().tween_property(line, "default_color:a", 0.0, 0.3)
	tween.tween_callback(line.queue_free)
	
	# Play attack animation
	$Sprite2D.animation = "attack"
	
	# Check for enemies in the attack path
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, attack_endpoint)
	query.collision_mask = 4  # Enemy collision layer
	var result = space_state.intersect_ray(query)
	
	print("Ray query result: " + str(result))
	
	var hit_enemy = false
	
	# Try direct raycast first
	if result and result.size() > 0:
		var collider = result["collider"]
		print("Hit collider: " + str(collider))
		
		if collider.has_method("enemy_damage") or collider.has_method("take_damage"):
			print("Applying damage to enemy: " + str(attack_damage))
			if collider.has_method("enemy_damage"):
				collider.enemy_damage(attack_damage)
			else:
				collider.take_damage()
				
			hit_enemy = true
			
			# Create hit effect at enemy location
			create_hit_effect(result["position"])
			
			# Create damage number
			var damage_number = damage_number_scene.instantiate()
			damage_number.position = result["position"]
			damage_number.set_damage(attack_damage)
			get_tree().current_scene.add_child(damage_number)
	
	# If no direct hit, try area detection
	if not hit_enemy:
		print("No direct hit, trying area detection")
		
		# Use a shape query to detect enemies in a small area around the endpoint
		var shape_query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 40  # Area of effect
		shape_query.set_shape(circle_shape)
		shape_query.transform = Transform2D(0, attack_endpoint)
		shape_query.collision_mask = 4  # Enemy collision layer
		
		var shape_results = space_state.intersect_shape(shape_query)
		print("Area query results: " + str(shape_results.size()) + " objects found")
		
		for shape_result in shape_results:
			var collider = shape_result["collider"]
			print("Area hit: " + str(collider.name))
			
			if collider.has_method("enemy_damage") or collider.has_method("take_damage"):
				print("Applying damage to enemy via area detection: " + str(attack_damage))
				if collider.has_method("enemy_damage"):
					collider.enemy_damage(attack_damage)
				else:
					collider.take_damage()
					
				hit_enemy = true
				
				# Create hit effect at enemy location
				create_hit_effect(collider.global_position)
				
				# Create damage number
				var damage_number = damage_number_scene.instantiate()
				damage_number.position = collider.global_position
				damage_number.set_damage(attack_damage)
				get_tree().current_scene.add_child(damage_number)
				break  # Only hit one enemy per attack
	
	if not hit_enemy:
		print("No enemy hit")

# Helper function to create hit effects
func create_hit_effect(position):
	var hit_effect = ColorRect.new()
	hit_effect.color = Color(1.0, 0.5, 0.0, 0.7)
	hit_effect.size = Vector2(30, 30)
	hit_effect.position = Vector2(-15, -15)
	get_parent().add_child(hit_effect)
	hit_effect.global_position = position
	
	var hit_tween = create_tween()
	hit_tween.tween_property(hit_effect, "color:a", 0.0, 0.3)
	hit_tween.tween_callback(hit_effect.queue_free)

# Add a specific function to handle area collisions with enemy bullets
func _on_body_entered(body):
	print("Tarzan body entered by: " + body.name)
	
	# Check if it's an enemy bullet
	if "enemy" in body.name.to_lower() or body.is_in_group("enemies"):
		print("Enemy collision detected!")
		if not is_invulnerable:
			player_damage(10)
