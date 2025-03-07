extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 50.0 
const SHOOT_COST := 20.0
const SWORD_COST := 40.0
const DOUBLE_JUMP_COST := 40.0

var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var jumping := false
var coyote := false
var facing_right := false
var coins := 0

var mouse_pos = Vector2.ZERO
var max_portal_distance = 300
@onready var ray_cast = $portal_pos
var current_portal_pos := Vector2.ZERO
var portal1 = Vector2.ZERO
var portal2 = Vector2.ZERO
var can_teleport := true
var can_teleport_timer := true

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	Global.has_shield = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
		
	if Input.is_action_just_pressed("ui_accept"):
		progress_bar.value -= 100
		mouse_pos = get_global_mouse_position()
		var dir_to_portal = global_position.direction_to(mouse_pos)
		ray_cast.target_position = dir_to_portal * max_portal_distance
		ray_cast.force_raycast_update()
		var collision_object = ray_cast.get_collider()
		
		if ray_cast.is_colliding():
			current_portal_pos = ray_cast.get_collision_point()
			match Global.portals:
				0:
					portal1 = current_portal_pos
					Global.portals = 1
				1:
					portal2 = current_portal_pos
					Global.portals = 2
				2:
					portal1 = current_portal_pos
					portal2 = Vector2.ZERO
					Global.portals = 1
			Global.portal1 = portal1
			Global.portal2 = portal2
			Global.shoot_portal = [true, global_position]
			
	if Input.is_action_just_pressed("switch"):
		var kill_radius: float = 70.0   
			
		for node in get_parent().get_children():
			if node is Area2D and node.has_method("enemy_damage"):
				var direction = node.global_position - global_position
				var distance = direction.length()
				if distance < kill_radius:
					node.enemy_damage(50)
	
	

	if can_teleport_timer and (global_position.distance_to(Global.portal1) < 50 or global_position.distance_to(Global.portal2) < 50):
		if global_position.distance_to(Global.portal1) < 50:
			global_position = Global.portal2
		elif global_position.distance_to(Global.portal2) < 50:
			global_position = Global.portal1
		can_teleport_timer = false
		teleport_timer()
		
			
		
	if not Global.dead:
		handle_normal_movement(delta)

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
		
	get_right_direc(direction)
	move_and_slide()

func coyote_change():
	await get_tree().create_timer(0.5).timeout
	coyote = false

func game_over() -> void:
	Global.dead = true
	Global.coins_collected = 0
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
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
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false
	
	
	
func teleport_timer():
	await get_tree().create_timer(15).timeout
	print('true')
	can_teleport_timer = true
