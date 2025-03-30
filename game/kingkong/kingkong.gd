extends CharacterBody2D

const ACCELERATION = 3000.0
var markers = []
var start_marker = null
var end_marker = null


func _ready() -> void:
	add_to_group('jungle_enemies')
	#choose markers belonging to the level of this enemy
	var x = get_parent()
	for node in x.get_children():
		if node is Marker2D:
			markers.append(node)
	
	
func _process(delta: float) -> void:
	if end_marker.global_position.distance_to(global_position) < 100:
		pass
	elif Global.player_position.distance_to(global_position) < 400:
		var direction = Global.player_position - global_position
		direction = direction.normalized()
		move_toward(velocity.x, direction.x * 120.0, ACCELERATION * delta)
	
	move_and_slide()
	
	
func raycasts():
	if Global.player_position.distance_to(global_position) > 150:
		return null
	var q = $"1"

	q.target_position = to_local(Global.player_position)

	q.force_raycast_update()


	
	if q.is_colliding() and q.get_collider().is_in_group('player'):
		return q.get_collider()
	else:
		return null

func get_closest_marker():
	start_marker = markers[0]
	end_marker = markers[0]
	for i in markers:
		#if i.global_position.distance_to(global_position) < start_marker.global_position.distance_to(global_position):
			#start_marker = i
		if i.global_position.distance_to(Global.player_position) < end_marker.global_position.distance_to(Global.player_position):
			end_marker = i
