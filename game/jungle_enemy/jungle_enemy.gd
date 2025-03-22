extends CharacterBody2D

var markers = []

var current_target
var current_bs := 0
var num_of_bs:int
var x
var jump = false
var cover_direc = [false, Vector2.ZERO] # left - false, right - true
var is_attacking = false
var is_covering
var he_knows = false
var player_node
var is_in_cover = [false, Vector2.ZERO]
var can_shoot = true

const ACCELERATION = 3000.0
const FRICTION = 2000.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	add_to_group('jungle_enemies')
	#choose markers belonging to the level of this enemy
	x = get_parent()
	var i := 0
	while x.get_node(str(i)) != null:
		if x.get_node(str(i)).global_position.y == global_position.y:
			markers.append(x.get_node(str(i)))
		i += 1




func raycasts():
	var q = $"Node2D/1"
	var w = $"Node2D/2"
	var e = $"Node2D/3"
	var r = $"Node2D/4"
	q.target_position = to_local(Global.player_position)
	w.target_position = to_local(Global.player_position)
	e.target_position = to_local(Global.player_position)
	r.target_position = to_local(Global.player_position)
	q.force_raycast_update()
	w.force_raycast_update()
	e.force_raycast_update()
	r.force_raycast_update()
	
	if q.is_colliding() and q.get_collider().is_in_group('player'):
		return q.get_collider()
	elif w.is_colliding() and w.get_collider().is_in_group('player'):
		return w.get_collider()
	elif e.is_colliding() and e.get_collider().is_in_group('player'):
		return e.get_collider()
	elif r.is_colliding() and r.get_collider().is_in_group('player'):
		return r.get_collider()
	else:
		return null



func _process(delta: float) -> void:
	if current_target:
		if to_local(current_target.global_position).x > 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false
	
	
	if ($jump.is_colliding() or $jump2.is_colliding()) and global_position.distance_to(is_in_cover[1]) > 60:
		velocity.y = -400.0
	if not $is_on_floor.is_colliding():
		position.y += 100 * delta
		
	var coll_object
	if not he_knows:
		coll_object = raycasts()
	else:
		coll_object = player_node
		
	if coll_object != null:
		current_target = coll_object
		player_node = coll_object
		he_knows = true
	
		for node in get_parent().get_children():
			if node is Area2D and node != self:
				if node.is_in_group("jungle_enemies"):
					attack()
					is_attacking = true
					break
					
		#is_attacking = true
		if is_attacking: # melee attack
			var direction = current_target.global_position - global_position
			global_position += direction.normalized() * 100 * delta
			is_attacking = false
			is_in_cover = [false, Vector2.ZERO]
			
		elif not is_attacking: # takes cover
			cover()
		
			var direction
			if cover_direc[0]:
				cover_direc[1].x += 40
				direction = (cover_direc[1]  - global_position).normalized()
			else:
				cover_direc[1].x -= 40
				direction = (cover_direc[1]  - global_position).normalized()
			is_in_cover = [true, cover_direc[1]]
			velocity.x = move_toward(velocity.x, direction.x * 300.0, ACCELERATION * delta)
			is_attacking = false
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
			
			
		

	
	
	#spearhit
	var shoot = $shoot
	if $Sprite2D.flip_h:
		shoot.target_position = Vector2(60, 0)
	else:
		shoot.target_position = Vector2(-60, 0)
	shoot.force_raycast_update()
	if shoot.is_colliding() and can_shoot:
		var shoot_coll = shoot.get_collider()
		if shoot_coll.is_in_group('player'):
			shoot_coll.player_damage(30)
			can_shoot = false
			shoot_timeout()
			
	
func shoot_timeout():
	await get_tree().create_timer(3).timeout
	can_shoot = true
		
	
func declassify_jump():
	await get_tree().create_timer(5).timeout
	jump = false
	

func attack():
	current_target = get_tree().root.get_node('player')
	
	
func cover():
	for node in get_parent().get_children():
		if node is StaticBody2D and node:
			var distance = global_position.distance_to(node.global_position)
			if distance < 150:
				if Global.player_position.x > node.global_position.x:
					cover_direc = [false, node.global_position]
				else:
					cover_direc = [true, node.global_position]
	
					
