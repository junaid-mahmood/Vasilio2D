extends Area2D

var velocity = Vector2.ZERO
@export var speed := 1000
var damage_multiplier := 1.0  # Default damage multiplier
var trail = null  # Reference to trail effect
var trail_points = []  # Store points for trail
const MAX_TRAIL_POINTS = 30  # Increased maximum trail points for longer trail
var damage_number_scene = preload("res://damage_number.tscn")

# Base damage values adjusted for enemy types
const BASE_DAMAGE_NORMAL = 32  # Standard damage for most enemies
const BASE_DAMAGE_JUNGLE = 8   # Significantly reduced damage for jungle enemies - barely effective
const BASE_DAMAGE_FLYING = 45  # Increased damage for flying enemies

func _ready():
	# Set the rotation based on the velocity
	rotation = velocity.angle()
	
	# Make the arrow smaller
	scale = Vector2(0.4, 0.4)
	
	# Add to bullets group for collision handling
	add_to_group("bullets")
	
	# Always create a trail, but make it more prominent for charged arrows
	create_trail()

func create_trail():
	# Remove any existing trail
	if trail != null and is_instance_valid(trail):
		trail.queue_free()
	
	# Create a new trail
	trail = Line2D.new()
	trail.width = 3.0 * (1.0 + damage_multiplier * 0.5)  # Width based on charge
	trail.default_color = Color(0, 0.7, 1, 0.8)  # Bright blue
	
	# Make trail fade out at the end
	var gradient = Gradient.new()
	gradient.colors = [Color(0, 0.7, 1, 0.8), Color(0, 0.7, 1, 0)]
	gradient.offsets = [0, 1]
	trail.gradient = gradient
	
	trail.z_index = -1  # Behind the arrow
	add_child(trail)
	
	# For charged arrows, add extra effects
	if damage_multiplier > 1.0:
		# Make the trail wider and longer
		trail.width = 6.0 * damage_multiplier
		
		# Add a glow effect to the arrow
		var glow = Sprite2D.new()
		glow.scale = Vector2(0.5, 0.5) * (1.0 + damage_multiplier * 0.5)
		glow.modulate = Color(0, 0.7, 1, 0.6)  # Blue glow
		add_child(glow)
		
		# Add particles for charged arrows
		var particles = CPUParticles2D.new()
		particles.amount = 20 * damage_multiplier
		particles.lifetime = 0.5
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		particles.direction = Vector2(-1, 0)
		particles.spread = 10
		particles.gravity = Vector2.ZERO
		particles.initial_velocity_min = 20
		particles.initial_velocity_max = 40
		particles.scale_amount_min = 2.0  # Use scale_amount_min instead of scale_amount
		particles.scale_amount_max = 3.0  # Add scale_amount_max for variation
		particles.color = Color(0, 0.7, 1, 0.6)  # Blue particles
		add_child(particles)

func _process(delta):
	# Move in the direction of velocity
	position += velocity * delta
	
	# Update trail
	if trail != null:
		# Add current position to trail points
		trail_points.push_front(Vector2.ZERO)  # Local position (0,0)
		
		# Limit the number of points
		if trail_points.size() > MAX_TRAIL_POINTS:
			trail_points.pop_back()
		
		# Update the trail
		trail.clear_points()
		
		# Calculate trail length based on damage multiplier and speed
		var trail_length = 30.0 * (1.0 + damage_multiplier * 0.5)
		
		for i in range(trail_points.size()):
			# Create a trail that extends backward from the arrow
			var point = Vector2(-trail_length * i / MAX_TRAIL_POINTS, 0).rotated(rotation)
			trail.add_point(point)
	
	# Check if the bullet has gone too far from the player
	var distance_from_player = position.distance_to(Global.player_position)
	if distance_from_player > 2000:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Handle collision with different bodies based on type
	if body.has_method("im_jungle_enemy"):
		# Apply reduced damage to jungle enemies
		var damage = BASE_DAMAGE_JUNGLE * damage_multiplier
		body.enemy_damage(round(damage))
		spawn_damage_number(body.global_position, damage)
	elif body is StaticBody2D:
		# Just destroy the arrow on static objects
		pass
		
	# Destroy the arrow when it hits something
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Check if area has enemy_damage method
	if area.has_method("enemy_damage"):
		var final_damage = BASE_DAMAGE_NORMAL * damage_multiplier
		
		# Apply different damage based on enemy type
		if area.has_method("im_jungle_enemy"):
			final_damage = BASE_DAMAGE_JUNGLE * damage_multiplier
		elif area.has_method("im_flying_enemy"):
			final_damage = BASE_DAMAGE_FLYING * damage_multiplier
		
		# Apply damage
		area.enemy_damage(round(final_damage))
		
		# Spawn damage number
		spawn_damage_number(area.global_position, final_damage)
		
	# Don't destroy if hitting another bullet
	if not area.is_in_group("bullets"):
		queue_free()

func spawn_damage_number(pos, damage):
	# Create the damage number instance
	var damage_number = damage_number_scene.instantiate()
	
	# Set the damage value
	damage_number.set_damage(round(damage))
	
	# Determine if it's a critical hit (for charged shots)
	var is_critical = damage_multiplier > 1.2
	if is_critical:
		damage_number.set_damage(round(damage), true)
	
	# Position it slightly above the hit position
	damage_number.global_position = pos + Vector2(0, -10)
	
	# Add it to the scene
	get_tree().get_root().add_child(damage_number)

func _this_is_bow():
	pass
