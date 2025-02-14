extends CharacterBody2D

const SHOOT_INTERVAL = 1.0  # Time between shots in seconds
const DETECTION_RANGE = 300.0  # How far the enemy can see

@onready var player: CharacterBody2D = get_node("../Player")  # Adjust the path to your player node
@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast: RayCast2D = $RayCast2D

var bullet_scene = preload("res://bullet.tscn")  # You'll need to create this scene

func _ready() -> void:
	# Setup shoot timer
	shoot_timer.wait_time = SHOOT_INTERVAL
	shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	shoot_timer.start()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
		
	# Check if player is in range and visible
	var distance = global_position.distance_to(player.global_position)
	if distance <= DETECTION_RANGE:
		# Look at player
		var direction = (player.global_position - global_position).normalized()
		ray_cast.target_position = direction * DETECTION_RANGE
		ray_cast.force_raycast_update()
		
		# Flip sprite based on player position
		sprite.flip_h = direction.x < 0
		
		# Check if there are obstacles between enemy and player
		if ray_cast.is_colliding() and ray_cast.get_collider() == player:
			shoot()

func shoot() -> void:
	if !shoot_timer.is_stopped():
		return
		
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	bullet.direction = direction
	
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	# Timer is used to control shooting frequency
	pass

func take_damage() -> void:
	# Implement damage handling here
	queue_free()  # For now, just destroy the enemy when hit
