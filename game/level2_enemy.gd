extends "res://static_enemy.gd"

var damage_number_scene = preload("res://damage_number.tscn")

func _ready():
	super._ready()
	
	# Load the texture
	var texture = preload("res://enemy/lv2enemy.png")
	$Sprite2D.texture = texture
	
	# Make the enemy EXTREMELY small
	$Sprite2D.scale = Vector2(0.05, 0.05)  # 5% of original size
	$CollisionShape2D.scale = Vector2(0.05, 0.05)
	
	# Ensure collision is working
	$CollisionShape2D.disabled = false
	
	# Print debug info
	print("Level2Enemy: Sprite scale set to " + str($Sprite2D.scale))
	print("Level2Enemy: Collision shape scale set to " + str($CollisionShape2D.scale))
	
	# Make sure we're in the right collision layer/mask
	collision_layer = 4  # Enemy layer
	collision_mask = 3   # Player and environment layers
	
	health = 5  # Make Level 2 enemies tougher
	detection_radius = 350  # Increase detection range
	shoot_cooldown = 1.5  # Slightly faster shooting
	$ShootTimer.wait_time = shoot_cooldown

# Add enemy_damage method to handle sword attacks
func enemy_damage(damage_amount):
	print("Level2Enemy: Taking damage: " + str(damage_amount))
	
	# Apply damage
	health -= 1
	
	# Spawn damage number
	spawn_damage_number(global_position, damage_amount)
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 0, 0, 1.0), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
	
	# Add a small "hit" animation
	var original_scale = $Sprite2D.scale
	tween.tween_property($Sprite2D, "scale", original_scale * 1.2, 0.1)
	tween.tween_property($Sprite2D, "scale", original_scale, 0.1)
	
	# Check if enemy is defeated
	if health <= 0:
		# Play death animation
		var death_tween = create_tween()
		death_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.5)
		death_tween.tween_callback(queue_free)

# Override the take_damage function to ensure proper visual feedback
func take_damage():
	print("Level2Enemy: take_damage called")
	
	health -= 1
	
	# Enhanced visual feedback for taking damage
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 0, 0, 1.0), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
	
	# Add a small "hit" animation
	var original_scale = $Sprite2D.scale
	tween.tween_property($Sprite2D, "scale", original_scale * 1.2, 0.1)
	tween.tween_property($Sprite2D, "scale", original_scale, 0.1)
	
	# Spawn damage number
	spawn_damage_number(global_position, 20)  # Base damage is 20
	
	if health <= 0:
		# Play death animation
		var death_tween = create_tween()
		death_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.5)
		death_tween.tween_callback(queue_free)

# Function to spawn damage numbers
func spawn_damage_number(pos, damage, is_critical = false):
	print("Level2Enemy: Spawning damage number: " + str(damage))
	
	# Create the damage number instance
	var damage_number = damage_number_scene.instantiate()
	
	# Set the damage value
	damage_number.set_damage(round(damage), is_critical)
	
	# Position it slightly above the hit position
	damage_number.global_position = pos + Vector2(0, -5)
	
	# Add it to the scene
	get_parent().add_child(damage_number)
	print("Level2Enemy: Damage number added to scene")

# Override the _on_area_entered function to handle damage from bow arrows
func _on_area_entered(area):
	print("Level2Enemy: Area entered: " + area.name)
	
	# Check if hit by player's arrow/bullet
	if area.has_method("_this_is_bow"):
		print("Level2Enemy: Hit by bow arrow")
		
		# Get damage multiplier if available (for charged shots)
		var damage_multiplier = 1.0
		if "damage_multiplier" in area:
			damage_multiplier = area.damage_multiplier
		
		# Apply damage
		health -= 1
		
		# Spawn damage number with critical if it's a charged shot
		var is_critical = damage_multiplier > 1.2
		spawn_damage_number(global_position, 20 * damage_multiplier, is_critical)
		
		# Visual feedback
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate", Color(1, 0, 0, 1.0), 0.1)
		tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
		
		# Check if enemy is defeated
		if health <= 0:
			# Play death animation
			var death_tween = create_tween()
			death_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.5)
			death_tween.tween_callback(queue_free) 
