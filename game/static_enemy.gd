extends Area2D

@onready var ray_cast = $RayCast2D
@export var detection_radius := 400  # Reasonable detection radius
var player_position
var health := 10  # Increased health to make it harder to kill
var can_shoot := true
var shoot_cooldown := 2.0  # Standard cooldown time

func _ready():
	# Add to enemies group
	add_to_group("enemies")
	
	# Force maintain exact original scale - prevent any size changes
	$Sprite2D.scale = Vector2(0.20219, 0.186956)
	
	# Completely disable the animation player
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
		$AnimationPlayer.queue_free()  # Remove the animation player entirely
	
	# Start the shooting timer
	$ShootTimer.wait_time = shoot_cooldown
	$ShootTimer.start()

func _process(delta):
	# Force sprite scale every frame to prevent any size changes
	if has_node("Sprite2D"):
		$Sprite2D.scale = Vector2(0.20219, 0.186956)
	
	# Get player position from global
	player_position = Global.player_position
	
	if player_position == Vector2.ZERO:
		return  # Player not initialized yet
	
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player_position)
	
	# Only shoot if player is within detection radius
	if distance_to_player <= detection_radius and can_shoot and not Global.dead:
		# Calculate direction to player
		var dir_to_player = global_position.direction_to(player_position)
		
		# Update raycast to check for obstacles
		ray_cast.target_position = dir_to_player * detection_radius
		ray_cast.force_raycast_update()
		
		# Check if raycast hit something
		var collision_object = ray_cast.get_collider()
		
		# If raycast didn't hit anything or hit player (clear line of sight to player)
		if collision_object == null or is_player(collision_object):
			# Get exact latest player position for accurate shooting
			var target_pos = Global.player_position
			
			# Adjust target position to aim at player's center
			target_pos.y -= 12  # Aim slightly higher to hit player center
			
			# Tell global that enemy is shooting
			Global.enemy_shoot = [true, global_position, target_pos]
			
			# Start cooldown
			can_shoot = false
			$ShootTimer.start()

# Helper function to check if a node is a player
func is_player(node):
	return node.is_in_group("player") or "tarzan" in node.name.to_lower() or "characterbody2d" in node.name.to_lower() or "teleport" in node.name.to_lower()

func take_damage():
	health -= 1
	
	# Visual feedback for taking damage - without animations
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
	
	# Shoot back immediately when hit
	if can_shoot and not Global.dead and player_position != Vector2.ZERO:
		# Get exact latest player position for accurate shooting
		var target_pos = Global.player_position
		
		# Tell global that enemy is shooting
		Global.enemy_shoot = [true, global_position, target_pos]
		
		# Start cooldown
		can_shoot = false
		$ShootTimer.start()
	
	if health <= 0:
		queue_free()

# Add enemy_damage method to handle Tarzan's attacks
func enemy_damage(damage_amount):
	# Reduce the damage amount to make enemy harder to kill
	health -= 0.5  # Now takes twice as many hits
	
	# Create damage number
	var damage_number = preload("res://damage_number.tscn").instantiate()
	damage_number.position = global_position + Vector2(0, -20)
	
	# Set the damage value using the correct method
	if damage_number.has_method("set_damage"):
		damage_number.set_damage(damage_amount)
	
	get_parent().add_child(damage_number)
	
	# Visual feedback for taking damage - without animations
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
	
	# Shoot back immediately when hit
	if can_shoot and not Global.dead and player_position != Vector2.ZERO:
		# Get exact latest player position for accurate shooting
		var target_pos = Global.player_position
		
		# Tell global that enemy is shooting
		Global.enemy_shoot = [true, global_position, target_pos]
		
		# Start cooldown
		can_shoot = false
		$ShootTimer.start()
	
	if health <= 0:
		queue_free()

func _on_shoot_timer_timeout():
	can_shoot = true
	
	# Try to shoot immediately when cooldown ends
	if player_position != Vector2.ZERO:
		var distance_to_player = global_position.distance_to(player_position)
		if distance_to_player <= detection_radius and not Global.dead:
			# Get exact latest player position for accurate shooting
			var target_pos = Global.player_position
			
			# Tell global that enemy is shooting
			Global.enemy_shoot = [true, global_position, target_pos]
			
			# Start cooldown
			can_shoot = false
			$ShootTimer.start()

func _on_area_entered(area):
	# Check if hit by player's arrow/bullet
	if area.has_method("_this_is_bow"):
		take_damage()
	# Check for Tarzan's attacks
	elif "tarzan" in area.name.to_lower():
		take_damage() 
