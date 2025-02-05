extends CPUParticles2D

func _ready() -> void:
	amount = 1
	lifetime = 1.0
	one_shot = true
	explosiveness = 1.0
	
	local_coords = false
	emitting = false
	
	direction = Vector2(1, 0)
	spread = 0
	initial_velocity_min = 800
	initial_velocity_max = 800
	
	scale_amount_min = 7
	scale_amount_max = 7
	
	gravity = Vector2(0, 0)

func _physics_process(_delta: float) -> void:
	if emitting:
		var space_state = get_world_2d().direct_space_state
		var check_pos = global_position + (direction * 20)
		var query = PhysicsRayQueryParameters2D.create(global_position, check_pos)
		query.collision_mask = 1
		
		var result = space_state.intersect_ray(query)
		if result:
			emitting = false
