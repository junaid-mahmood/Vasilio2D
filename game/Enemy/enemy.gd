
extends CharacterBody2D

@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D = get_node("../Player")

var health = 100
var can_shoot = true
var is_attacking = false
var is_dying = false
var is_hit = false
const HEALTH_REGEN_RATE = 2.0
const MAX_HEALTH = 40.0

var base_scale = Vector2(0.40, 0.40)
const MANUAL_SCALE_FACTORS = {
	"default": 1.0,
	"attack": 0.9,
	"hit": 0.9,
	"death": 0.9
}

# Random shooting variables
const MIN_SHOOT_DELAY = 1.5  # Minimum time between shots
const MAX_SHOOT_DELAY = 3.0  # Maximum time between shots

var base_texture_size: Vector2

func _ready() -> void:
	var default_texture = sprite_2d.sprite_frames.get_frame_texture("default", 0)
	base_texture_size = default_texture.get_size() if default_texture else Vector2.ONE
	
	# Set initial random timer delay
	timer.wait_time = randf_range(MIN_SHOOT_DELAY, MAX_SHOOT_DELAY)
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()
	
	if sprite_2d:
		sprite_2d.animation_finished.connect(_on_animation_finished)
		sprite_2d.animation_changed.connect(_on_animation_changed)
		for anim in ["attack", "hit", "death"]:
			sprite_2d.sprite_frames.set_animation_loop(anim, false)
		sprite_2d.play("default")
	
	particles.amount = 1
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.scale_amount_min = 2
	particles.scale_amount_max = 2
	particles.initial_velocity_min = 400
	particles.initial_velocity_max = 400
	particles.color = Color(1, 0, 0, 1)
	particles.spread = 0
	particles.gravity = Vector2.ZERO

func _adjust_animation_scale(anim_name: String) -> void:
	if not sprite_2d:
		return
	
	var current_texture = sprite_2d.sprite_frames.get_frame_texture(anim_name, 0)
	if not current_texture:
		push_error("Texture for animation %s not found!" % anim_name)
		return
	
	var current_size = current_texture.get_size()
	if current_size.x == 0 or current_size.y == 0:
		push_error("Invalid texture size for animation %s" % anim_name)
		return
	
	var size_ratio = base_texture_size / current_size
	var manual_factor = MANUAL_SCALE_FACTORS.get(anim_name, 1.0)
	sprite_2d.scale = base_scale * size_ratio * manual_factor

func _on_animation_changed() -> void:
	_adjust_animation_scale(sprite_2d.animation)

func shoot() -> void:
	if not can_shoot or not player or is_dying or is_attacking or is_hit:
		return
	
	is_attacking = true
	sprite_2d.play("attack")
	
	var direction = (player.global_position - global_position).normalized()
	particles.direction = direction
	particles.emitting = true
	sprite_2d.flip_h = direction.x < 0
	
	can_shoot = false
	# Set random delay for next shot
	timer.wait_time = randf_range(MIN_SHOOT_DELAY, MAX_SHOOT_DELAY)
	timer.start()

func take_damage() -> void:
	if is_dying or is_hit:
		return
		
	health -= 20
	
	if health <= 0:
		die()
	else:
		is_hit = true
		is_attacking = false
		sprite_2d.play("hit")

func die() -> void:
	if is_dying:
		return
	
	is_dying = true
	is_attacking = false
	is_hit = false
	can_shoot = false
	
	sprite_2d.play("death")
	await sprite_2d.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dying:
		return
		
	if health < MAX_HEALTH:
		health = min(health + HEALTH_REGEN_RATE * delta, MAX_HEALTH)
	
	if player and can_shoot and not is_attacking and not is_hit:
		shoot()

func _on_timer_timeout() -> void:
	can_shoot = true
func _on_animation_finished() -> void:
	match sprite_2d.animation:
		"attack":
			# Shoot only after the attack animation finishes
			var direction = (player.global_position - global_position).normalized()
			particles.direction = direction
			particles.emitting = true
			sprite_2d.flip_h = direction.x < 0
			
			is_attacking = false
			sprite_2d.play("default")
		"hit":
			is_hit = false
			sprite_2d.play("default")
		"death":
			pass
