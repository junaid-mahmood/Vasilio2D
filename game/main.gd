extends Node

const bullet_scene: PackedScene = preload("res://character/bullet.tscn")
const enemy_bullet_scene: PackedScene = preload("res://enemy/enemy_bullet.tscn")
const portal_bullet_scene: PackedScene = preload("res://teleport/portal.tscn")
const bow_bullet_scene: PackedScene = preload("res://bow/bow_bullet.tscn")

var player_character

func _ready() -> void:
	if Global.player == 'tarzan':
		player_character = load("res://tarzan/tarzan.tscn").instantiate() 
		player_character.position = Vector2(79, 600)
		
	elif Global.player == 'classic':
		player_character = load("res://character/character_body_2d.tscn").instantiate()
		player_character.position = Vector2(79, 611)
		
	elif Global.player == 'scientist':
		player_character = load("res://teleport/teleport.tscn").instantiate()
		player_character.position = Vector2(79, 600)
	
	add_child(player_character)
	
	# Ensure Bullets node exists
	if not has_node("Bullets"):
		var bullets_node = Node2D.new()
		bullets_node.name = "Bullets"
		add_child(bullets_node)
	
	# Ensure EnemyBullets node exists
	if not has_node("EnemyBullets"):
		var enemy_bullets_node = Node2D.new()
		enemy_bullets_node.name = "EnemyBullets"
		add_child(enemy_bullets_node)

func _process(delta: float) -> void:
	if Global.shoot[0]:
		var pos = Global.shoot[1]
		
		# Check if using bow/arrow
		if Global.weapon == 'bow':
			var bow_bullet = bow_bullet_scene.instantiate()
			
			# For bow, the third parameter is the target position
			var target_pos = Global.shoot[2]
			var spawn_pos = Global.shoot[1]
			
			# Calculate direction from spawn position to target
			var direction = (target_pos - spawn_pos).normalized()
			
			# Set bullet position and velocity
			bow_bullet.position = spawn_pos
			bow_bullet.velocity = direction * bow_bullet.speed
			
			# Set rotation to match direction
			bow_bullet.rotation = direction.angle()
			
			# Apply damage multiplier if provided (from charged attack)
			if Global.shoot.size() > 3:
				bow_bullet.damage_multiplier = Global.shoot[3]
				
				# Scale the arrow based on charge
				if Global.shoot[3] > 1.0:
					var scale_factor = 0.4 + (Global.shoot[3] - 1.0) * 0.2
					bow_bullet.scale = Vector2(scale_factor, scale_factor)
			
			# Add the bullet to the scene
			if has_node("Bullets"):
				$Bullets.add_child(bow_bullet)
			else:
				# Create Bullets node if it doesn't exist
				var bullets_node = Node2D.new()
				bullets_node.name = "Bullets"
				add_child(bullets_node)
				bullets_node.add_child(bow_bullet)
			
			# Reset shoot flag
			Global.shoot[0] = false
		else:
			# Original gun logic
			var facing_right = Global.shoot[2]
			var bullet = bullet_scene.instantiate()
			var direction = 1 if facing_right else -1
			bullet.direction = direction
			$Bullets.add_child(bullet)
			pos.y -= 20
			bullet.position = pos + Vector2(6 * direction, 0)
			Global.shoot[0] = false
		
	# Handle enemy shooting with debug logging
	if Global.enemy_shoot[0]:
		print("Enemy shooting triggered in main.gd")
		var pos = Global.enemy_shoot[1]
		var player_pos = Global.enemy_shoot[2]
		
		# Create the bullet
		var en_bullet = enemy_bullet_scene.instantiate()
		print("Enemy bullet instantiated: " + str(en_bullet))
		
		# Position the bullet
		pos.y -= 20
		en_bullet.position = pos
		
		# Set velocity and direction
		var direction: Vector2 = (player_pos - pos).normalized()
		en_bullet.velocity = direction * en_bullet.speed
		en_bullet.rotation = direction.angle()
		
		# Debug the bullet properties
		print("Bullet position: " + str(en_bullet.position))
		print("Bullet velocity: " + str(en_bullet.velocity))
		print("Bullet collision layer: " + str(en_bullet.collision_layer))
		print("Bullet collision mask: " + str(en_bullet.collision_mask))
		
		# Add to scene
		if has_node("EnemyBullets"):
			print("Adding enemy bullet to EnemyBullets node")
			$EnemyBullets.add_child(en_bullet)
		else:
			print("EnemyBullets node not found, creating it")
			var enemy_bullets_node = Node2D.new()
			enemy_bullets_node.name = "EnemyBullets"
			add_child(enemy_bullets_node)
			enemy_bullets_node.add_child(en_bullet)
		
		# Reset the global flag
		Global.enemy_shoot[0] = false
		print("Enemy shooting completed")
		
	if Global.shoot_portal[0]:
		await get_tree().create_timer(1)
		var pos = Global.shoot_portal[1]
		var portal_bullet = portal_bullet_scene.instantiate()
		var direction := Vector2.ZERO
		if Global.portals == 1:
			direction = (Global.portal1 - pos).normalized()
			
		elif Global.portals == 2:
			direction = (Global.portal2 - pos).normalized()
			
		portal_bullet.position = pos
		portal_bullet.velocity = direction * portal_bullet.speed
		portal_bullet.rotation = direction.angle()
		if Global.portals == 1:
			portal_bullet.set_pos = Global.portal1
		else:
			portal_bullet.set_pos = Global.portal2
		$EnemyBullets.add_child(portal_bullet)
		Global.shoot_portal[0] = false
		
