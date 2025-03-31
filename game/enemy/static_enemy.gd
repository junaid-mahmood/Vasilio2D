extends CharacterBody2D

var health = 3
var can_shoot = true
var shoot_cooldown = 2.0
var detection_radius = 300.0
var player_in_sight = false
var player_position = Vector2.ZERO

func _ready():
	# Keep original scale - important!
	scale = Vector2(1, 1)
	
	# Configure shooting timer
	$shoot_cooldown.wait_time = shoot_cooldown
	$shoot_cooldown.start()

func _process(delta):
	# Get player position from Global
	player_position = Global.player_position
	
	if player_position != Vector2.ZERO:
		var distance_to_player = global_position.distance_to(player_position)
		
		# Check if player is within detection radius
		if distance_to_player <= detection_radius:
			# Check line of sight using raycast
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, player_position)
			query.collision_mask = 3  # Environment layers
			var result = space_state.intersect_ray(query)
			
			# If no collision or collision is with player, we have line of sight
			var has_line_of_sight = result.is_empty() or (result.has("collider") and is_player(result["collider"]))
			
			if has_line_of_sight:
				player_in_sight = true
				
				# If we can shoot, do so
				if can_shoot:
					shoot()
			else:
				player_in_sight = false
		else:
			player_in_sight = false

# Helper function to check if a node is a player
func is_player(node):
	return node.is_in_group("player") or node.name.begins_with("tarzan") or node.name.begins_with("CharacterBody2D") or node.name.begins_with("teleport")

func shoot():
	if can_shoot:
		can_shoot = false
		$shoot_cooldown.start()
		
		# Exact targeting - get latest position
		var exact_target_pos = Global.player_position
		
		# Set up the global shoot parameters with precise aiming
		Global.enemy_shoot = [true, global_position, exact_target_pos]
		
		# Visual feedback for shooting
		$AnimatedSprite2D.play("attack")
		await get_tree().create_timer(0.5).timeout
		$AnimatedSprite2D.play("idle")

func _on_shoot_cooldown_timeout():
	can_shoot = true

# Add enemy_damage method to handle Tarzan's attacks
func enemy_damage(damage_amount):
	# Actually use the damage amount instead of just reducing by 1
	health -= damage_amount / 10  # Divide by 10 to make it take multiple hits
	
	# Create damage number
	var damage_number = preload("res://damage_number.tscn").instantiate()
	damage_number.position = global_position + Vector2(0, -20)
	
	# Set the damage value using the correct method
	if damage_number.has_method("set_damage"):
		damage_number.set_damage(damage_amount)
	elif damage_number.has_method("set_damage_value"):
		damage_number.set_damage_value(damage_amount)
	
	get_parent().add_child(damage_number)
	
	# Visual feedback for taking damage
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
	
	if health <= 0:
		# Play death animation if available, otherwise just free
		queue_free() 
