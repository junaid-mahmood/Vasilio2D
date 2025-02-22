extends Control

var player_has_barrel = false

func _ready() -> void:
	if has_node("GridContainer/Button4"):
		$GridContainer/Button4.visible = false
		print("Button4 hidden at start")
	
	get_tree().create_timer(0.1).timeout.connect(Callable(self, "find_and_connect_player"))

func find_and_connect_player() -> void:
	var player = get_node_or_null("../../Player")
	if not player:
		player = get_node_or_null("/root/Main/Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	if player:
		print("Found player node:", player)
		if player.has_signal("barrel_inventory_changed"):
			player.connect("barrel_inventory_changed", Callable(self, "_on_barrel_inventory_changed"))
			print("Connected to player barrel signal")
		else:
			print("Player doesn't have barrel_inventory_changed signal")
		
		if player.has_method("pickup_barrel") and player.has_method("use_barrel_from_inventory"):
			# This is our correct player with barrel support
			print("Player has barrel support")
		else:
			print("Player found but doesn't have barrel methods")

func _process(delta: float) -> void:
	update_hotbar_selection()

func _on_button_pressed() -> void:
	Global.weapon = false

func _on_button_2_pressed() -> void:
	Global.weapon = true

func _on_button_3_pressed() -> void:
	Global.weapon = false

func _on_button_4_pressed() -> void:
	if player_has_barrel:
		var player = find_player()
		if player and player.has_method("use_barrel_from_inventory"):
			player.use_barrel_from_inventory()

func _on_barrel_inventory_changed(has_barrel: bool) -> void:
	print("HOTBAR RECEIVED BARREL SIGNAL:", has_barrel)
	player_has_barrel = has_barrel
	update_barrel_visibility()

func update_hotbar_selection() -> void:
	if has_node("GridContainer/Button"):
		$GridContainer/Button.modulate = Color(1, 1, 1, 1) if not Global.weapon else Color(0.5, 0.5, 0.5, 1)
	
	if has_node("GridContainer/Button2"):
		$GridContainer/Button2.modulate = Color(1, 1, 1, 1) if Global.weapon else Color(0.5, 0.5, 0.5, 1)

func update_barrel_visibility() -> void:
	if has_node("GridContainer/Button4"):
		$GridContainer/Button4.visible = player_has_barrel
		print("Button4 visibility updated to:", player_has_barrel)

func find_player():
	var player = get_node_or_null("../../Player")
	if not player:
		player = get_node_or_null("/root/Main/Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	return player
