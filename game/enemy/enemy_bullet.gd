extends Area2D

@export var speed: float = 1000
var velocity: Vector2 = Vector2.ZERO
var damage: int = 20

func _ready():
	print("Enemy bullet created with collision layer: " + str(collision_layer) + ", mask: " + str(collision_mask))
	
	# Connect the body_entered signal
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)
		print("Connected body_entered signal")
	
	# Connect the area_entered signal
	if not is_connected("area_entered", _on_area_entered):
		connect("area_entered", _on_area_entered)
		print("Connected area_entered signal")

func _process(delta):
	position += velocity * delta
	
	# Destroy bullet if it goes too far off screen
	if position.distance_to(Vector2(0, 0)) > 2000:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("Bullet hit body: " + body.name)
	
	# Check if the body is the player (more inclusive check)
	if body.name == "tarzan" or "tarzan" in body.name.to_lower() or "character" in body.name.to_lower() or body.is_in_group("player"):
		print("Bullet hit player: " + body.name)
		if body.has_method("player_damage"):
			print("Applying damage to player: " + str(damage))
			body.player_damage(damage)
		else:
			print("Player doesn't have player_damage method")
			# Try to find the player_damage method in parent nodes
			var parent = body.get_parent()
			if parent and parent.has_method("player_damage"):
				print("Found player_damage in parent")
				parent.player_damage(damage)
	
	# Always destroy the bullet on collision
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	print("Bullet hit area: " + area.name)
	
	# Check if the area is the player (more inclusive check)
	if area.name == "tarzan" or "tarzan" in area.name.to_lower() or "character" in area.name.to_lower() or area.is_in_group("player"):
		print("Bullet hit player area: " + area.name)
		if area.has_method("player_damage"):
			print("Applying damage to player area: " + str(damage))
			area.player_damage(damage)
		else:
			print("Player area doesn't have player_damage method")
			# Try to find the player_damage method in parent nodes
			var parent = area.get_parent()
			if parent and parent.has_method("player_damage"):
				print("Found player_damage in parent")
				parent.player_damage(damage)
	
	# Always destroy the bullet on collision
	queue_free()
