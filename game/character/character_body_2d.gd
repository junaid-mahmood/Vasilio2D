extends CharacterBody2D

signal shoot(pos, bool)
var facing_right = true
var coins := 0
var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var shield := false
var DISTANCE_SHIELD := 40
var shield_body
var weapon_counter := 0  # Starting with gun (index 0)
var weapons = ["gun", "sword", "shield"]

signal player_pos(pos)
signal new_coin(coins)
signal has_shield(shield)
signal pla_pos_shield(new_pos)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 50.0 
const SHOOT_COST := 20.0
const SWORD_COST := 40.0
const DOUBLE_JUMP_COST := 40.0

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node_or_null("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node_or_null("../CanvasLayer/HealthBar")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump := false

func _ready():
	if progress_bar:
		progress_bar.max_value = 100
		progress_bar.value = 100
	
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = 100
	
	var parent = get_parent()
	shield_body = parent.get_node_or_null("shield")
	if shield_body:
		shield_body.visible = false  # Make sure shield is invisible at start
	
	# Initialize with gun selected
	Global.weapon = "gun"

func _physics_process(delta):
	if health_bar and health_bar.value <= 0:
		game_over()
	
	check_door_collision()
	
	var centered_global_position = global_position
	centered_global_position.y -= 20
	centered_global_position.x += 9
	var mouse_pos = get_global_mouse_position()
	var direc_to_mouse = (mouse_pos - centered_global_position).normalized()
	var angle_radians = atan2(direc_to_mouse.y, direc_to_mouse.x)
	var shield_pos = centered_global_position + Vector2(cos(angle_radians), sin(angle_radians)) * DISTANCE_SHIELD
	emit_signal("pla_pos_shield", shield_pos)
	
	if angle_radians and shield_body:
		shield_body.rotation = angle_radians
	
	if shield_body:
		if Global.weapon == 'shield':
			shield_body.visible = true
			emit_signal("has_shield", true)
		else:
			shield_body.visible = false
			emit_signal("has_shield", false)
		
	if Input.is_action_just_pressed("switch"):
		weapon_counter += 1
		if weapon_counter > 2:
			weapon_counter = 0
		Global.weapon = weapons[weapon_counter]
	
	if progress_bar and progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	if Global.weapon == 'sword':
		sprite_2d.animation = "sword"
	elif abs(velocity.x) > 1:
		sprite_2d.animation = "running"
	else:
		sprite_2d.animation = "default"
		
	if is_on_floor():
		can_double_jump = true
	
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite_2d.animation = "jumping"

	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif can_double_jump and progress_bar and progress_bar.value >= DOUBLE_JUMP_COST:
			velocity.y = JUMP_VELOCITY * 1.1
			progress_bar.value -= DOUBLE_JUMP_COST
			can_double_jump = false
	
	if Input.is_action_just_pressed("ui_select"):
		if Global.weapon == 'gun' and progress_bar and progress_bar.value >= SHOOT_COST:
			progress_bar.value -= SHOOT_COST
			print("Shooting gun")
			shoot.emit(global_position, facing_right)
		elif Global.weapon == 'sword' and progress_bar and progress_bar.value >= SWORD_COST:
			progress_bar.value -= SWORD_COST
			sprite_2d.animation = 'sword'
			var kill_radius: float = 70.0   
				
			for node in get_parent().get_children():
				if node is Area2D and node.has_method("enemy_damage"):
					var direction_to_enemy = node.global_position - global_position
					var distance = direction_to_enemy.length()
					if distance < kill_radius:
						node.enemy_damage(50)

	var move_direction = Input.get_axis("ui_left", "ui_right")
	if move_direction != 0:
		if (move_direction < 0 and velocity.x > 0) or (move_direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, move_direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	move_and_slide()
	get_right_direc(move_direction)
	
	if velocity.x != 0:
		sprite_2d.flip_h = velocity.x < 0
		
	emit_signal("player_pos", position)

func check_door_collision():
	# Find doors and check distance
	for door in get_tree().get_nodes_in_group("Area2D"):
		if "door" in door.name.to_lower():
			var distance = global_position.distance_to(door.global_position)
			if distance < 50:
				print("Player has touched the door!")
				force_change_scene()
				return
				
	# Direct check for door node
	var door_node = get_node_or_null("../Door")
	if door_node:
		var distance = global_position.distance_to(door_node.global_position)
		if distance < 50:
			print("Player has touched the Door node!")
			force_change_scene()
			return

func force_change_scene():
	print("FORCE CHANGING SCENE to Level 2")
	
	# Try different methods to change the scene
	
	# Method 1: Direct call
	var err = get_tree().change_scene_to_file("res://level2.tscn")
	if err == OK:
		print("Successfully changed scene using method 1")
		return
	
	print("Method 1 failed, trying method 2")
	
	# Method 2: Try to manually load the resource
	var packed_scene = ResourceLoader.load("res://level2.tscn")
	if packed_scene:
		print("Resource loaded, trying to change scene")
		err = get_tree().change_scene_to_packed(packed_scene)
		if err == OK:
			print("Successfully changed scene using method 2")
			return
	
	print("All methods failed, could not change scene")
		
func get_right_direc(move_direction):
	if move_direction != 0:
		facing_right = move_direction >= 0

func player_damage(number):
	if is_invulnerable or not health_bar:
		return
	health_bar.value -= number
	var tween = create_tween()
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 0.0, 0.1)
		
	is_invulnerable = true
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false

func game_over():
	print("Game Over!")
	get_tree().reload_current_scene()

func coin_collected(num):
	coins += num
	emit_signal("new_coin", coins)
	var plus_one = get_node_or_null("+1")
	if plus_one:
		plus_one.visible = true
		var collect_timer = get_node_or_null("collect")
		if collect_timer:
			collect_timer.start()

func _on_collect_timeout():
	var plus_one = get_node_or_null("+1")
	if plus_one:
		plus_one.visible = false

func _on_barrel_2_explo_damage(num):
	player_damage(num)

func _on_barrel_3_explo_damage(num):
	player_damage(num)

func _on_barrel_explo_damage(num):
	player_damage(num)
