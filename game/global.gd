extends Node
var weapon := 'bow'
var player := 'tarzan'
var player_position := Vector2.ZERO
var dead := false
var has_shield := false
var coins_collected := 0
var shop_coins := 0

#if shooting, player_pos, direction
var shoot = [false, Vector2.ZERO, Vector2.ZERO]

#if shooting, enemy_pos, target_pos
var enemy_shoot = [false, Vector2.ZERO, Vector2.ZERO]
var shoot_portal = [false, Vector2.ZERO]
var player_node = ''
var portal1 = Vector2.ZERO
var portal2 = Vector2.ZERO
var portals = 0

var see_player = []

var level_changed = false
var quantum_acceleration_active = false
var quantum_acceleration_cooldown = 0.0
var quantum_acceleration_max_cooldown = 5.0

# Player stats that can be upgraded in shop
var max_health := 100
var player_speed_multiplier := 1.0
var damage_multiplier := 1.0
var jump_boost := 1.0  # Base multiplier

# New variables for level coin requirements
var coins_required = {
	"res://main.tscn": 31,
	"res://level2.tscn": 20,
	"res://level_3.tscn": 69,
}

# Track which coins have been collected in each level
var collected_coin_ids = {}
var coins_collected_per_level = {}

# Setter functions to ensure type safety
func set_weapon(new_weapon) -> void:
	if typeof(new_weapon) == TYPE_STRING:
		weapon = new_weapon
	else:
		push_error("Attempted to set weapon to non-string: " + str(new_weapon))
		weapon = 'sword' # Fallback to default

func set_player(new_player) -> void:
	if typeof(new_player) == TYPE_STRING:
		player = new_player
	else:
		push_error("Attempted to set player to non-string: " + str(new_player))
		player = 'tarzan' # Fallback to default

func get_required_coins():
	var current_scene = get_tree().current_scene.scene_file_path
	if coins_required.has(current_scene):
		return coins_required[current_scene]
	return 0
	
func is_level_complete():
	return coins_collected >= get_required_coins()
<<<<<<< Updated upstream
=======

func add_coin(amount: int = 1, coin_id: String = "") -> void:
	# Get current level path
	var current_scene = get_tree().current_scene.scene_file_path
	
	# If a coin_id was provided, check if this coin was already collected
	if coin_id != "":
		# Skip if already collected
		if is_coin_collected(coin_id):
			print("Coin " + coin_id + " already collected, skipping")
			return
		
		# Mark as collected
		mark_coin_collected(coin_id)
	
	# Initialize level counters if needed
	if not coins_collected_per_level.has(current_scene):
		coins_collected_per_level[current_scene] = 0
	
	# Add coins to both counters
	coins_collected_per_level[current_scene] += amount
	coins_collected += amount
	shop_coins += amount
	
	print("Coins added: " + str(amount) + ", Level total: " + str(coins_collected_per_level[current_scene]) + ", Overall total: " + str(coins_collected))

# Check if a coin has already been collected
func is_coin_collected(coin_id: String) -> bool:
	var current_scene = get_tree().current_scene.scene_file_path
	
	# Initialize if needed
	if not collected_coin_ids.has(current_scene):
		collected_coin_ids[current_scene] = []
	
	# Check if the coin ID exists in the collected list
	return coin_id in collected_coin_ids[current_scene]

# Mark a coin as collected
func mark_coin_collected(coin_id: String) -> void:
	var current_scene = get_tree().current_scene.scene_file_path
	
	# Initialize if needed
	if not collected_coin_ids.has(current_scene):
		collected_coin_ids[current_scene] = []
	
	# Add to the collected list if not already there
	if not coin_id in collected_coin_ids[current_scene]:
		collected_coin_ids[current_scene].append(coin_id)
		print("Marked coin " + coin_id + " as collected in " + current_scene)

func purchase_item(cost: int) -> bool:
	print("Attempting to purchase item costing " + str(cost) + " coins. Available: " + str(shop_coins))
	if shop_coins >= cost:
		shop_coins -= cost
		print("Purchase successful. Remaining coins: " + str(shop_coins))
		return true
	print("Purchase failed - not enough coins")
	return false

func reset_game_state() -> void:
	dead = false
	weapon = 'bow'
	player_position = Vector2.ZERO
	has_shield = false
	
	# Don't reset coins or collected coin IDs on death
	# This means coins stay collected when player respawns
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

func enable_upgrade_2():
	jump_boost = 1.5  # 50% higher jump when upgrade is enabled
>>>>>>> Stashed changes
