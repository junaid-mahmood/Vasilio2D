extends Node
var weapon := 'bow'
var player_position := Vector2.ZERO
var dead := false
var has_shield := false
var coins_collected := 0

#if shooting, player_pos, direction
var shoot = [false, Vector2.ZERO, Vector2.ZERO]

#if shooting, enemy_pos, target_pos
var enemy_shoot = [false, Vector2.ZERO, Vector2.ZERO]
var shoot_portal = [false, Vector2.ZERO]
var player = ''
var portal1 = Vector2.ZERO
var portal2 = Vector2.ZERO
var portals = 0

var see_player = []

var level_changed = false
var quantum_acceleration_active = false
var quantum_acceleration_cooldown = 0.0
var quantum_acceleration_max_cooldown = 5.0

# New variables for level coin requirements
var coins_required = {
	"res://main.tscn": 1,
	"res://level2.tscn": 2,
	"res://level_3.tscn": 67
}


func get_required_coins():
	var current_scene = get_tree().current_scene.scene_file_path
	if coins_required.has(current_scene):
		return coins_required[current_scene]
	return 0
	
func is_level_complete():
	return coins_collected >= get_required_coins()

func reset_game_state() -> void:
	dead = false
	weapon = 'bow'
	player_position = Vector2.ZERO
	has_shield = false
	# Don't reset coins on death
	# coins_collected = 0
	shoot = [false, Vector2.ZERO, Vector2.ZERO]
	enemy_shoot = [false, Vector2.ZERO, Vector2.ZERO]
	shoot_portal = [false, Vector2.ZERO]
	portal1 = Vector2.ZERO
	portal2 = Vector2.ZERO
	portals = 0
	see_player = []
	level_changed = false
	quantum_acceleration_active = false
	quantum_acceleration_cooldown = 0.0
