extends CharacterBody2D

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
@onready var particles: CPUParticles2D = $CPUParticles2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump := false
var health := 100.0
var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0  # Time in seconds of invulnerability after being hit


func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = health

func shoot_particles() -> void:
	if progress_bar.value >= SHOOT_COST and particles:
		progress_bar.value -= SHOOT_COST
		particles.position = sprite_2d.position + Vector2(0, -16)
		particles.direction = Vector2(-1, 0) if sprite_2d.flip_h else Vector2(1, 0)
		particles.restart()
		particles.emitting = true
		
		# Create area for particle collision
		var area = Area2D.new()
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 5
		collision.shape = shape
		area.add_child(collision)
		add_child(area)
		area.global_position = global_position + particles.direction * 20
		area.connect("body_entered", Callable(self, "_on_particle_hit"))
		await get_tree().create_timer(0.1).timeout
		area.queue_free()

func take_damage() -> void:
	if is_invulnerable:
		return
		
	health -= 20  # Reduce health by 20
	health_bar.value = health
	
	# Add invulnerability period
	is_invulnerable = true
	sprite_2d.modulate.a = 0.5  # Make sprite semi-transparent
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false
	sprite_2d.modulate.a = 1.0  # Restore sprite opacity
	
	if health <= 0:
		game_over()

func game_over() -> void:
	# Handle player death here
	print("Game Over!")
	# Optional: Restart level or show game over screen
	get_tree().reload_current_scene()

func _on_particle_hit(body: Node2D) -> void:
	if body.has_method("take_damage") and body.name == "Enemy":
		body.take_damage()

func _physics_process(delta: float) -> void:
	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	if abs(velocity.x) > 1:
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
		elif can_double_jump and progress_bar.value >= DOUBLE_JUMP_COST:
			velocity.y = JUMP_VELOCITY * 1.1
			progress_bar.value -= DOUBLE_JUMP_COST
			can_double_jump = false
			
	if Input.is_action_just_pressed("ui_select"):
		shoot_particles()
		
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	move_and_slide()
	
	if velocity.x != 0:
		sprite_2d.flip_h = velocity.x < 0
