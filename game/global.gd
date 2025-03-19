extends Node
var weapon := 'bow'
var player_position := Vector2.ZERO
var dead := false
var has_shield := false
var coins_collected := 0
var shoot = [false, Vector2.ZERO, false]
var enemy_shoot = [false, Vector2.ZERO, Vector2.ZERO]
var shoot_portal = [false, Vector2.ZERO]
var player = ''
var portal1 = Vector2.ZERO
var portal2 = Vector2.ZERO
var portals = 0
var level_changed = false
var quantum_acceleration_active = false
var quantum_acceleration_cooldown = 0.0
var quantum_acceleration_max_cooldown = 5.0

# New variables for level coin requirements
var coins_required = {
	"res://main.tscn": 12,
	"res://level2.tscn": 1,
	"res://level_3.tscn": 5
}

func get_required_coins():
	var current_scene = get_tree().current_scene.scene_file_path
	if coins_required.has(current_scene):
		return coins_required[current_scene]
	return 0
	
func is_level_complete():
	return coins_collected >= get_required_coins()
