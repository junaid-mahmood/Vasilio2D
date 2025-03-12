extends Area2D

var velocity = Vector2.ZERO
@export var speed := 1000
var damage_multiplier := 1.0  # Default damage multiplier
var trail = null  # Reference to trail effect
var trail_points = []  # Store points for trail
const MAX_TRAIL_POINTS = 30  # Increased maximum trail points for longer trail

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
	# Destroy the arrow when it hits something
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Check if area has enemy_damage method
	if area.has_method("enemy_damage"):
		# Apply damage with multiplier
		var base_damage = 30  # Base arrow damage
		var final_damage = base_damage * damage_multiplier
		area.enemy_damage(final_damage)
	
	# Don't destroy if hitting another bullet
	if not area.is_in_group("bullets"):
		queue_free()

func _this_is_bow():
	pass
