extends Area2D

@export var explosion: PackedScene = preload("res://barrel/explosion.tscn")
var damage := 0
signal explo_damage(num)
var health := 15

func _ready():
	# Set up collision layer and mask for both Area2D and StaticBody2D
	if has_node("StaticBody2D"):
		var static_body = $StaticBody2D
		static_body.collision_layer = 1
		static_body.collision_mask = 1
		
	collision_layer = 2
	collision_mask = 2
	
	# Set up solid collision shape if it doesn't exist
	if has_node("StaticBody2D") and not $StaticBody2D.has_node("CollisionShape2D"):
		var collision_shape = CollisionShape2D.new()
		var rectangle_shape = RectangleShape2D.new()
		rectangle_shape.size = Vector2(32, 32)  # Adjust size to match your barrel
		collision_shape.shape = rectangle_shape
		$StaticBody2D.add_child(collision_shape)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("_this_is_bow"):
		take_damage(40)
	elif area.has_method("_this_is_bullet"):
		take_damage(10)
	else:
		take_damage(health)  # Instant destruction for other collisions

func take_damage(amount: int) -> void:
	health -= amount
	print("Barrel health: ", health)
	if health <= 0:
		destroy()

func destroy():
	# Disable both collisions
	if has_node("StaticBody2D"):
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	
	spawn_explosion()
	apply_explosion_impulse()

func spawn_explosion():
	var explosion_instance = explosion.instantiate()
	explosion_instance.position = global_position
	explosion_instance.rotation = global_rotation
	explosion_instance.emitting = true
	get_tree().current_scene.add_child(explosion_instance)
	queue_free()

func apply_explosion_impulse():
	var kill_radius: float = 30.0   
	var push_radius: float = 50.0  
	var impulse_power: float = 200.0
	var player_vertical_boost: float = 5.0  
	var player_damage_reduction: float = 0.15  
	
	for node in get_parent().get_children():
		if node is CharacterBody2D:
			var direction = node.global_position - global_position
			var distance = direction.length()
			
			var damage_amount = 0
			if distance < 60:
				damage_amount = int(200 * player_damage_reduction)
			elif distance < 90:
				damage_amount = int(99 * player_damage_reduction)
			elif distance < 110:
				damage_amount = int(60 * player_damage_reduction)
			elif distance < 140:
				damage_amount = int(40 * player_damage_reduction)
			
			if damage_amount > 0:
				emit_signal("explo_damage", damage_amount)
			
			if distance < push_radius:
				var force_direction = direction.normalized()
				force_direction.y = -1.0  
				force_direction = force_direction.normalized() * player_vertical_boost
				var boost_power = impulse_power * 2.0  
				node.velocity += force_direction * boost_power
		
		elif node is RigidBody2D:
			var direction = node.global_position - global_position
			var distance = direction.length()
			if distance < kill_radius:
				node.queue_free()
			elif distance < push_radius:
				node.apply_central_impulse(direction.normalized() * impulse_power)
		
		elif node is Area2D:
			var direction = node.global_position - global_position
			var distance = direction.length()
			if distance < kill_radius and node != self:
				if node.has_method("destroy"):
					node.destroy()
				else:
					node.queue_free()
