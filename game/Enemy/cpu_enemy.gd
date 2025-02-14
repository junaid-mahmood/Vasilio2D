extends CPUParticles2D

func _physics_process(_delta: float) -> void:
	if not emitting:
		return
	
	var space_state = get_world_2d().direct_space_state
	var start_pos = global_position
	var end_pos = start_pos + (direction * 400)
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 1
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result["collider"]
		if collider.name == "Player":
			collider.take_damage()  # Removed the damage parameter
