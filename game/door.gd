extends Area2D

var is_player_in_door = false
var player_body = null

func _ready():
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _process(delta):
	var is_unlocked = Global.is_level_complete()
	modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.5, 0.5, 0.5, 1)

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_in_door = true
		player_body = body
		
		if Global.is_level_complete():
			# Force scene change with small delay to ensure it happens
			get_tree().create_timer(0.1).timeout.connect(force_change_scene)
		else:
			if body.has_method("show_message"):
				body.show_message("Collect all coins first!")

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_in_door = false
		player_body = null

func force_change_scene():
	if not is_player_in_door or not Global.is_level_complete():
		return
		
	Global.level_changed = true
	Global.coins_collected = 0
	
	var current_path = get_tree().current_scene.scene_file_path.to_lower()
	var next_scene = ""
	
	if "main.tscn" in current_path:
		next_scene = "res://level2.tscn"
	elif "level2.tscn" in current_path:
		next_scene = "res://level_3.tscn"
		
	if next_scene != "":
		call_deferred("_deferred_change_scene", next_scene)

func _deferred_change_scene(next_scene):
	get_tree().change_scene_to_file(next_scene)
