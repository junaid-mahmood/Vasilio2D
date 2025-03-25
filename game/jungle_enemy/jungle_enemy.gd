extends CharacterBody2D

var markers = []
var path_to_player

var current_target
var end_marker
var start_marker
var current_bs := 0
var num_of_bs:int
var x
var jump = true
var cover_direc = [false, Vector2.ZERO] # left - false, right - true
var is_attacking = false
var is_covering
var he_knows = false
var player_node
var is_in_cover = [false, Vector2.ZERO]
var can_shoot = true

var speed_multiplier = 1.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	add_to_group('jungle_enemies')
	#choose markers belonging to the level of this enemy
	x = get_parent()
	for node in x.get_children():
		if node is Marker2D:
			markers.append(node)


func get_closest_marker():
	start_marker = markers[0]
	end_marker = markers[0]
	for i in markers:
		if i.global_position.distance_to(global_position) < start_marker.global_position.distance_to(global_position):
			start_marker = i
		if i.global_position.distance_to(Global.player_position) < end_marker.global_position.distance_to(Global.player_position):
			end_marker = i

	
			
			

func find_bfs_path(start_id: int, target_id: int) -> Array:
	var graph = {}
	var id_to_node = {}
	# Build graph struct
	for marker in markers:
		var name_parts = marker.name.split("_", false, 2)
		if name_parts.size() < 2:
			continue 
		
		var current_id = int(name_parts[0])
		var connections_str = name_parts[1].strip_edges()
		var connected_ids = []
		
		if connections_str:
			var connections = connections_str.split(",")
			for conn in connections:
				conn = conn.strip_edges()
				if conn.is_valid_int():
					connected_ids.append(int(conn))
		
		graph[current_id] = connected_ids
		id_to_node[current_id] = marker

	# if start and end are in graph
	if not graph.has(start_id) or not graph.has(target_id):
		return []

	# bfs algo
	var queue = [start_id]
	var visited = {start_id: true}
	var parent = {}
	
	while not queue.is_empty():
		var current_id = queue.pop_front()
		
		# if i found target
		if str(current_id) == str(target_id):
			# reconstruction of path
			var path_ids = []
			var node_id = target_id
			while node_id != start_id:
				path_ids.append(node_id)
				node_id = parent.get(node_id, -1)
				if node_id == -1:
					return []  # i fuccked soemthing up if this is triggered
			path_ids.append(start_id)
			path_ids.reverse()
			
			# id to node
			var path_nodes = []
			for id in path_ids:
				if id_to_node.has(id):
					path_nodes.append(id_to_node[id])
				else:
					return []  # another place where my fuckup is found
			return path_nodes
		

		
		# find neighbor non-visited nodes
		for neighbor_id in graph.get(int(current_id), []):
			if not visited.has(int(neighbor_id)):
				visited[int(neighbor_id)] = true
				parent[int(neighbor_id)] = int(current_id)
				queue.append(int(neighbor_id))

	return []



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
	
	bfs_setup()
	
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

	if ($jump.is_colliding() or $jump2.is_colliding()) and is_on_floor():
		velocity.y = -450.0
		
	if not is_on_floor():
		speed_multiplier = 1.7
	else:
		speed_multiplier = 1.0
	
	
	if current_target:
		if to_local(current_target.global_position).x > 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false
			
			
	bfs_all_shit(delta)
			
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
	
	
		
		

		
		
		
func bfs_all_shit(delta):
	var coll_object
	if Global.see_player != null:
		coll_object = Global.see_player
		he_knows = true
	elif not he_knows:
		coll_object = raycasts()
	else:
		coll_object = player_node
	
	var close = false
	if coll_object != null:
		#basically always focusing on player
		Global.see_player = coll_object	
		
		player_node = coll_object
		he_knows = true
		

		#checks if is_alone
		'''
		for node in get_parent().get_children():
			if node is CharacterBody2D and node != self and node.global_position.distance_to(global_position) < 200:
				if node.is_in_group("jungle_enemies"):
					attack()
					is_attacking = true
					break
		'''
		is_attacking = true # override to attack

		if is_attacking and not close: # melee attack
			if path_to_player:
				current_target = path_to_player[0]
			else:
				bfs_setup()
				return
			if abs(global_position.x - path_to_player[0].global_position.x) < 5:
				path_to_player.pop_front()
				if len(path_to_player) == 1:
					current_target = path_to_player[0]
					pass
				elif not path_to_player:
					current_target = end_marker

			print(current_target)
			print(path_to_player)
			
			var direction = current_target.global_position - global_position
			direction = direction.normalized()
	
			if global_position.y >= current_target.global_position.y + 15 and velocity.y >= 0 and abs(global_position.x - current_target.global_position.x) > 15:
				velocity.y = -450.0
			velocity.x = move_toward(velocity.x, direction.x * 120.0 * speed_multiplier, ACCELERATION * delta)
			is_attacking = false
			is_in_cover = [false, Vector2.ZERO]
			
		elif not close and not is_attacking: # takes cover
			cover()
			var direction
			if cover_direc[0]:
				cover_direc[1].x += 40
				direction = (cover_direc[1]  - global_position).normalized()
			else:
				cover_direc[1].x -= 40
				direction = (cover_direc[1]  - global_position).normalized()
			is_in_cover = [true, cover_direc[1]]
			velocity.x = move_toward(velocity.x, direction.x * 150.0, ACCELERATION * delta)
			is_attacking = false
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	
		

			
			
func is_any_node_close():
	for node in markers:
		if global_position.distance_to(node.global_position) <= 25:
			return node
	return null
	

func bfs_setup():
	get_closest_marker()
	var start_marker_ids = start_marker.name.split('_')
	var start_marker_id = start_marker_ids[0]
	var end_marker_ids = end_marker.name.split('_')
	var end_marker_id = end_marker_ids[0]
	path_to_player = find_bfs_path(int(start_marker_id), int(end_marker_id))

func manual_bfs_setup(start_marker_manual):
	get_closest_marker()
	var start_marker_ids = start_marker_manual.name.split('_')
	var start_marker_id = start_marker_ids[0]
	var end_marker_ids = end_marker.name.split('_')
	var end_marker_id = end_marker_ids[0]
	path_to_player = find_bfs_path(int(start_marker_id), int(end_marker_id))
	
	
func shoot_timeout():
	await get_tree().create_timer(3).timeout
	can_shoot = true
		
	
	
func declassify_jump():
	await get_tree().create_timer(1).timeout
	jump = true
	

func cover():
	for node in get_parent().get_children():
		if node is StaticBody2D and node:
			var distance = global_position.distance_to(node.global_position)
			if distance < 150:
				if Global.player_position.x > node.global_position.x:
					cover_direc = [false, node.global_position]
				else:
					cover_direc = [true, node.global_position]
	
					
