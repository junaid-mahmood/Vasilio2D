extends CPUParticles2D

func _ready() -> void:
	amount = 1
	lifetime = 0.5
	one_shot = true
	explosiveness = 1.0
	
	local_coords = false
	emitting = false
	
	direction = Vector2(1, 0)
	spread = 0
	initial_velocity_min = 400
	initial_velocity_max = 400
	
	scale_amount_min = 7
	scale_amount_max = 7
	
	gravity = Vector2(0, 0)

func _physics_process(_delta: float) -> void:
	if not emitting:
		return
	
	var space_state = get_world_2d().direct_space_state
	var start_pos = global_position
	var end_pos = start_pos + (direction * 400)
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 1 | 2  # Layer 0 and Enemy layer
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result["collider"]
		if collider.name == "Enemy":
			collider.take_damage()
			
		# Don't stop emitting, let particles finish their animation
		# The lifetime property will handle cleanup automatically
