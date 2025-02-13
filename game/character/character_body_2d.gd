extends CharacterBody2D

signal shoot(pos, bool)
var facing_right = true


signal player_pos(pos)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 50.0 
const SHOOT_COST := 20.0
const DOUBLE_JUMP_COST := 40.0

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump := false  # New variable to track double jump availability

func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100


func _physics_process(delta: float) -> void:
	#check if game ends
	if health_bar.value <= 0:
		queue_free()
	
	
	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	if abs(velocity.x) > 1:
		sprite_2d.animation = "running"
	else:
		sprite_2d.animation = "default"
		
	# Reset double jump when touching the ground
	if is_on_floor():
		can_double_jump = true
	
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite_2d.animation = "jumping"

	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif can_double_jump and progress_bar.value >= DOUBLE_JUMP_COST:
			velocity.y = JUMP_VELOCITY * 1.1
			progress_bar.value -= DOUBLE_JUMP_COST
			can_double_jump = false  # Prevent additional double jumps until landing

	if Input.is_action_just_pressed("ui_select"):
		progress_bar.value -= SHOOT_COST
		shoot.emit(global_position, facing_right)

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	move_and_slide()
	get_right_direc(direction)
	
	if velocity.x != 0:
		sprite_2d.flip_h = velocity.x < 0
		
	emit_signal("player_pos", position)
		
func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

func player_damage(number):
	health_bar.value -= number


func _on_barrel_explo_damage(num: Variant) -> void:
	player_damage(num)
