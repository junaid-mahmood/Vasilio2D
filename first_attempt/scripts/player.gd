extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -250.0
const ladder_speed = 500
@onready var sprite = $AnimatedSprite2D  # Ensure this path is correct
var jumps = 0
var max_jumps = 2
var on_ladder:bool = false
var animation = 'idle'

var health := 100

const DASH_SPEED = 500.0
var dashing:bool = false

var facing_right := true

var has_gun:bool = false 
var can_shoot := true

signal shoot(pos, facing_right)



func _physics_process(delta: float) -> void:
	
	
	if not is_on_floor() and !on_ladder:
		velocity += get_gravity() * delta
		
	#dash
	if Input.is_action_just_pressed("dash"):
		dashing = true
		$dash_timer.start()
		
		
		
		
	#ladder
	if on_ladder:
		if Input.is_action_pressed("go_down"):
			velocity.y = ladder_speed*delta*10
		elif Input.is_action_pressed("go_up"):
			velocity.y = -ladder_speed*delta*10
		else:
			velocity.y = 0
			
	#double jump
	if is_on_floor():
		jumps = 0
	if Input.is_action_just_pressed("ui_accept") and jumps < max_jumps:
		velocity.y = JUMP_VELOCITY
		jumps += 1

	#dash
	if dashing:
		if has_gun:
			$AnimatedSprite2D.animation = 'dash+gun'
		else:
			$AnimatedSprite2D.animation = 'dash'
			
		if facing_right:
			velocity.x = 1 * DASH_SPEED
		else:
			velocity.x = -1 * DASH_SPEED
		
	#movement
	var direction := Input.get_axis("go_left", "go_right")
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
		
		
		
	#animated
	if direction != 0 and !has_gun and !dashing:
		$AnimatedSprite2D.animation = 'run'
	elif direction != 0 and has_gun and !dashing:
		$AnimatedSprite2D.animation = 'run+gun'
	else:
		if !has_gun and !dashing:
			$AnimatedSprite2D.animation = 'idle'
		elif has_gun and !dashing:
			$AnimatedSprite2D.animation = 'idle+gun'
		
	#can shoot?
	if 'gun' not in $AnimatedSprite2D.animation:
		can_shoot = false
	else:
		can_shoot = true
		
	#shooting
	if Input.is_action_just_pressed("just_shoot") and can_shoot:
		shoot.emit(global_position, facing_right)
	
	
	
		
	get_right_direc(direction)
	move_and_slide()

func set_on_ladder(state: bool) -> void:
	on_ladder = state
	
func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

func _on_dash_timer_timeout():
	dashing = false
	
func player_damage(amount):
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($AnimatedSprite2D, "material:shader_parameter/amount", 0.0, 0.1).set_delay(0.2)
	health -= amount
	if health <= 0:
		get_tree().quit()
