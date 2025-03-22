extends Control

@onready var label = $Label
var key_icon
var key_visible = false
var required_coins = 0
var previously_completed = false
var current_level = ""
var level_completion_status = {}

func _ready():
	create_key_icon()
	hide_key()
	current_level = get_tree().current_scene.scene_file_path
	update_required_coins()
	
	# Force hide key at start of any level
	if key_icon and is_instance_valid(key_icon):
		key_icon.visible = false
	key_visible = false

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Cleanup when node is deleted
		if key_icon and is_instance_valid(key_icon):
			key_icon.queue_free()

func create_key_icon():
	# Remove any existing key icon first
	if key_icon and is_instance_valid(key_icon):
		key_icon.queue_free()
	
	key_icon = Sprite2D.new()
	key_icon.texture = preload("res://thekey.png") 
	key_icon.visible = false
	key_icon.scale = Vector2(0.08, 0.08)  
	get_tree().root.add_child(key_icon)

func _process(delta):
	var coins = Global.coins_collected
	label.text = str(coins)
	
	# Check if level changed
	var new_level = get_tree().current_scene.scene_file_path
	if new_level != current_level:
		# Level changed - reset everything
		hide_key()
		current_level = new_level
		update_required_coins()
		previously_completed = false
		
		# Force reset
		if key_icon and is_instance_valid(key_icon):
			key_icon.queue_free()
			key_icon = null
		create_key_icon()
		
		# Save completion status for previous level
		if Global.coins_collected >= required_coins:
			level_completion_status[current_level] = true
		else:
			level_completion_status[current_level] = false
			
		# Reset coins for new level check
		previously_completed = false
	
	if required_coins == 0:
		update_required_coins()
	
	# Check if current level's coins requirement is met
	var currently_completed = (coins >= required_coins)
	
	# Only show key if current level's requirement is met
	if currently_completed and not previously_completed:
		show_key_above_player()
	elif not currently_completed and key_visible:
		hide_key()
	
	previously_completed = currently_completed
	
	# Update key position if visible
	if key_visible and key_icon and is_instance_valid(key_icon):
		var player = find_player()
		if player:
			key_icon.global_position = player.global_position - Vector2(0, 100)
			
			var door = find_door()
			if door and player.global_position.distance_to(door.global_position) < 70:
				hide_key()

func hide_key():
	key_visible = false
	if key_icon and is_instance_valid(key_icon):
		key_icon.visible = false

func update_required_coins():
	var current_scene = get_tree().current_scene.scene_file_path
	var level_map = {
		"res://main.tscn": "res://main.tscn",
		"res://level2.tscn": "res://level2.tscn",
		"res://level_3.tscn": "res://level_3.tscn"
	}
	
	var scene_path = current_scene
	if level_map.has(scene_path) and Global.coins_required.has(level_map[scene_path]):
		required_coins = Global.coins_required[level_map[scene_path]]
	else:
		required_coins = 0

func show_key_above_player():
	# Only show key if we're in a level and have met its requirements
	if current_level.is_empty() or Global.coins_collected < required_coins:
		return
		
	var player = find_player()
	if player:
		# Ensure the key icon exists
		if not key_icon or not is_instance_valid(key_icon):
			create_key_icon()
			
		key_visible = true
		key_icon.visible = true
		key_icon.global_position = player.global_position - Vector2(0, 100)

func find_player():
	var player_nodes = ["CharacterBody2D", "tarzan", "teleport"]
	
	for name in player_nodes:
		var player = get_tree().root.find_child(name, true, false)
		if player:
			return player
	
	return null

func find_door():
	return get_tree().root.find_child("Door", true, false)
