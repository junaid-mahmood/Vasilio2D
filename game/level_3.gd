extends Node

const bullet_scene: PackedScene = preload("res://character/bullet.tscn")
const enemy_bullet_scene: PackedScene = preload("res://enemy/enemy_bullet.tscn")
const portal_bullet_scene: PackedScene = preload("res://teleport/portal.tscn")
const bow_bullet_scene: PackedScene = preload("res://bow/bow_bullet.tscn")
const teleport_hotbar: PackedScene = preload("res://hotbar_teleport.tscn")
const tarzan_hotbar: PackedScene = preload("res://hotbar_tarzan.tscn")
const classic_hotbar: PackedScene = preload("res://hotbar.tscn")

var player_character

@export var interact_distance: float = 50.0

func _ready() -> void:
	var hotbar_instance
	var canvas
	canvas = get_node("CanvasLayer")
	
	if Global.player == 'tarzan':
		player_character = load("res://tarzan/tarzan.tscn").instantiate() 
		player_character.position = Vector2(110.0, -20.0)
		hotbar_instance = tarzan_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
		
	elif Global.player == 'classic':
		player_character = load("res://character/character_body_2d.tscn").instantiate()
		player_character.position = Vector2(110.0, -20.0)
		hotbar_instance = classic_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
		
	elif Global.player == 'scientist':
		player_character = load("res://teleport/teleport.tscn").instantiate()
		player_character.position = Vector2(110.0, -20.0)
		hotbar_instance = teleport_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
	
	canvas.add_child(hotbar_instance)
	
	add_child(player_character)
	Vector2(110.0, -6.0)

func _process(delta: float) -> void:
	if Global.shoot[0]:
		if Global.weapon == 'bow':
			var bow_bullet = bow_bullet_scene.instantiate()
			var direc_bow = Global.shoot[2]
			var spawn_pos = Global.shoot[1]
		
			bow_bullet.position = spawn_pos
			bow_bullet.velocity = direc_bow * bow_bullet.speed
			bow_bullet.rotation = direc_bow.angle()
	
			$Bullets.add_child(bow_bullet)
			Global.shoot[0] = false
			
		else:
			var pos = Global.shoot[1]
			var facing_right = Global.shoot[2]
			var bullet = bullet_scene.instantiate()
			var direction = 1 if facing_right else -1
			bullet.direction = direction
			$Bullets.add_child(bullet)
			pos.y -= 20
			bullet.position = pos + Vector2(6 * direction, 0)
			Global.shoot[0] = false
		
	if Global.enemy_shoot[0]:
		var pos = Global.enemy_shoot[1]
		var player_pos = Global.enemy_shoot[2]
		
		var en_bullet = enemy_bullet_scene.instantiate()		
		pos.y -= 20
		en_bullet.position = pos
		# Set velocity and direction
		var direction: Vector2 = (player_pos - pos).normalized()
		en_bullet.velocity = direction * en_bullet.speed
		en_bullet.rotation = direction.angle()
		$EnemyBullets.add_child(en_bullet)
		Global.enemy_shoot[0] = false

		
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
	
	if Input.is_action_just_pressed("start"):
		var nearest_torch = get_nearest_torch()
		if nearest_torch:
			nearest_torch.toggle_torch()
		
		
func get_nearest_torch():
	var player = get_tree().get_first_node_in_group("player")
	var nearest: Node2D = null
	var nearest_dist = interact_distance
	for torch in get_tree().get_nodes_in_group("torches"):
		var distance = player.global_position.distance_to(torch.global_position)
		if distance < nearest_dist:
			nearest = torch
			nearest_dist = distance
	return nearest
