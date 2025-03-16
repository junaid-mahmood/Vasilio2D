extends Node2D

@export var interact_distance: float = 50.0


func _process(delta: float) -> void:
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
