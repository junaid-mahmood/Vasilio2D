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

var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var can_change_ani := true

var coins := 0


func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	Global.has_shield = false


func coyote_change():
	await get_tree().create_timer(0.5).timeout
	coyote = false



func _process(delta: float) -> void:
	Global.player_position = position
	if is_on_floor():
		coyote = true
		jumping = false
	else:
		coyote_change()
		jump_catch()
		
	if not is_on_floor():
		head_catch()
		
	
	if health_bar.value <= 0:
		game_over()
		
	if Input.is_action_just_released("start") and hooked: 
		hooked = false
		motion = Vector2.ZERO
		$"extra+damage".start()
	
	#hook
	if Input.is_action_just_pressed("start") and progress_bar.value >= 10:
		progress_bar.value -= 10
		mouse_pos = get_global_mouse_position()
		var dir_to_grapple = global_position.direction_to(mouse_pos)
		ray_cast.target_position = dir_to_grapple * rope_length 
		ray_cast.force_raycast_update()
		var collision_object = ray_cast.get_collider()
		
		if ray_cast.is_colliding():
			GRAPPLE_POS = ray_cast.get_collision_point()
			DISTANCE_GRAPPLE = global_position.distance_to(GRAPPLE_POS)
			current_rope_length = DISTANCE_GRAPPLE  
			hooked = true
			was_hooked = true
			motion = velocity 
			
		
	if Input.is_action_pressed("ui_accept") and progress_bar.value == 100:
		progress_bar.value -= 100
		mouse_pos = get_global_mouse_position()
		var dir_to_grapple = global_position.direction_to(mouse_pos)
		ray_cast.target_position = dir_to_grapple * rope_length 
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
		
	if Input.is_action_just_pressed("switch"):
		print($stab/ShapeCast2D.get_collider(0))
		
		
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
		velocity.y = JUMP_VELOCITY
		jumping = true
		
	if Input.is_action_just_released('ui_up') and jumping:
		velocity.y = 0
		jumping = false
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
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
		
func head_catch():
	if $"catch head/left_stop".is_colliding() and not $"catch head/left_stop".is_colliding():
		position.x -= 30
	elif $"catch head/right_stop".is_colliding() and not $"catch head/right_go".is_colliding():
		position.x += 30
		

func _on_collect_timeout() -> void:
	$"+1".visible = false
