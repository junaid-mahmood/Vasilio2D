extends CanvasLayer

# Item definitions
var items = [
	{
		"id": "health_upgrade",
		"cost": 5,
		"effect": "health",
		"amount": 25,
		"description": "Health +25%"
	},
	{
		"id": "jump_upgrade",
		"cost": 10,
		"effect": "jump",
		"amount": 50,
		"description": "Jump +50%"
	},
	{
		"id": "damage_upgrade",
		"cost": 15,
		"effect": "damage",
		"amount": 1,
		"description": "Damage +1"
	}
]

var shop_open := false

func _ready() -> void:
	# Use normal process mode since we're not pausing the game
	process_mode = Node.PROCESS_MODE_INHERIT
	
	# Hide the shop on start
	$Panel.visible = false
	shop_open = false
	
	# Connect the close button - make sure to use the correct Callable format
	if not $Panel/CloseButton.is_connected("pressed", Callable(self, "_on_close_button_pressed")):
		$Panel/CloseButton.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	# Connect buy buttons
	for i in range(3):
		var button_path = "Panel/ItemGrid/Item" + str(i+1) + "/BuyButton"
		var button = get_node(button_path)
		
		if button:
			# Disconnect any existing connections to avoid duplicates
			if button.is_connected("pressed", Callable(self, "_on_item_buy_pressed")):
				button.disconnect("pressed", Callable(self, "_on_item_buy_pressed"))
			
			# Connect with the proper Callable format and bind parameter
			button.connect("pressed", Callable(self, "_on_item_buy_pressed").bind(i))
			
			# Style the button text to be yellow to match screenshot
			var font_color = Color(1, 1, 0, 1)  # Yellow
			button.add_theme_color_override("font_color", font_color)
		
		# Set item descriptions
		var desc_label = get_node("Panel/ItemGrid/Item" + str(i+1) + "/Description")
		if desc_label:
			desc_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))

# Show the shop UI
func open_shop() -> void:
	# Show the shop panel
	$Panel.visible = true
	shop_open = true
	
	# Update the coin display
	$Panel/CoinCounter/Value.text = str(Global.shop_coins)
	
	# Only update button states based on affordability
	for i in range(3):
		var button_path = "Panel/ItemGrid/Item" + str(i+1) + "/BuyButton"
		var button = get_node(button_path)
		
		if button:
			# Make sure button can receive input
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			
			# Enable/disable based on coin amount
			if Global.shop_coins >= items[i]["cost"]:
				button.disabled = false
			else:
				button.disabled = true
	
	# Ensure the shop panel has proper focus mode
	$Panel.mouse_filter = Control.MOUSE_FILTER_STOP

# Hide the shop UI
func close_shop() -> void:
	# Hide the shop panel
	$Panel.visible = false
	shop_open = false

func _on_close_button_pressed() -> void:
	close_shop()

func _on_item_buy_pressed(item_index: int) -> void:
	var item = items[item_index]
	
	# Check if player has enough coins
	if Global.shop_coins >= item["cost"]:
		# Purchase successful
		if Global.purchase_item(item["cost"]):
			# Apply the effect
			apply_item_effect(item)
			
			# Update the shop UI
			$Panel/CoinCounter/Value.text = str(Global.shop_coins)
			
			# Play purchase sound
			if $PurchaseSound.stream != null:
				$PurchaseSound.play()
			
			# Update buy buttons
			for i in range(3):
				var button = get_node("Panel/ItemGrid/Item" + str(i+1) + "/BuyButton")
				if button:
					if Global.shop_coins >= items[i]["cost"]:
						button.disabled = false
					else:
						button.disabled = true

# Apply the effect of a purchased item
func apply_item_effect(item: Dictionary) -> void:
	# Apply different effects based on the item type
	match item["effect"]:
		"health":
			# Increase max health by the specified amount
			Global.max_health += item["amount"]
			
			# Find the player and update their current health
			var player = get_player_node()
			if player:
				var health_bar = player.get_node_or_null("../CanvasLayer/HealthBar")
				if health_bar:
					# Update max health on the bar
					health_bar.max_value = Global.max_health
					
					# Also heal the player by the same amount
					health_bar.value += item["amount"]
			
		"jump":
			# Add jump height boost to global 
			if not "jump_boost" in Global:
				Global.jump_boost = 1.0  # Start with base multiplier of 1.0 (100%)
			else:
				# Add percentage boost (e.g., +50% means multiplier goes from 1.0 to 1.5)
				Global.jump_boost += (item["amount"] / 100.0)
			
			# Find the player and update their jump strength
			var player = get_player_node()
			if player:
				# Try multiple approaches to modify jump height
				
				# Method 1: Direct JUMP_VELOCITY property (most common in Godot CharacterBody2D)
				if "JUMP_VELOCITY" in player:
					# Make jump higher (negative velocity in Godot means up)
					var base_jump = -400.0  # Typical base jump value
					player.JUMP_VELOCITY = base_jump * Global.jump_boost
				
				# Method 2: jump_velocity lowercase property
				elif "jump_velocity" in player:
					var base_jump = -400.0
					player.jump_velocity = base_jump * Global.jump_boost
				
				# Method 3: Set a meta property that can be checked in player script
				player.set_meta("jump_boost", Global.jump_boost)
				
				# Method 4: Look for a jump-related function
				if player.has_method("set_jump_height"):
					player.set_jump_height(Global.jump_boost)
				
				# Print for debugging
				print("Applied jump boost: " + str(Global.jump_boost) + "x")
			
		"damage":
			Global.damage_multiplier += item["amount"]

# Helper function to find the player node
func get_player_node():
	# Try to find player in different ways
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player
		
	# Look for common player node names
	var player_nodes = ["CharacterBody2D", "tarzan", "teleport", "Player"]
	for node_name in player_nodes:
		player = get_tree().root.find_child(node_name, true, false)
		if player:
			return player
	
	# If still not found, try a more exhaustive search
	var root_children = get_tree().root.get_children()
	for child in root_children:
		if child.get_class() == "Node2D" or child.get_class() == "Node3D":
			player = find_player_recursive(child)
			if player:
				return player
	
	return null

# Recursive helper to find player in the scene tree
func find_player_recursive(node):
	if "velocity" in node and node.has_method("_physics_process"):
		return node
		
	for child in node.get_children():
		var result = find_player_recursive(child)
		if result:
			return result
	
	return null

# Handle input (for closing shop with ESC, opening with S key, and buying with number keys)
func _input(event: InputEvent) -> void:
	# Shop is open - handle shop-specific inputs
	if shop_open:
		# Close the shop when ESC is pressed
		if event.is_action_pressed("ui_cancel"):
			close_shop()
		
		# Buy items with number keys 1-3
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1:
				_on_item_buy_pressed(0)
			elif event.keycode == KEY_2:
				_on_item_buy_pressed(1)
			elif event.keycode == KEY_3:
				_on_item_buy_pressed(2)
	
	# Shop is closed - check if we should open it
	elif not shop_open and event is InputEventKey and event.keycode == KEY_S and event.pressed and not event.echo:
		open_shop() 
