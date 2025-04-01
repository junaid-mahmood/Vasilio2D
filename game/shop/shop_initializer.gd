extends Node

const shop_button_scene: PackedScene = preload("res://shop/shop_button.tscn")
const shop_scene: PackedScene = preload("res://shop/shop.tscn")
var shop_button
var shop_instance

func _ready() -> void:
	# Wait a frame to ensure the scene is fully loaded
	await get_tree().process_frame
	
	# First, add the shop button to the UI
	add_shop_button()
	
	# Then add the shop scene to the game
	add_shop_scene()
	
	# Connect signals
	connect_signals()
	
	print("Shop system initialized. Press S key to open shop.")

func add_shop_button() -> void:
	# Try to find the CanvasLayer
	var canvas_layer = get_tree().root.find_child("CanvasLayer", true, false)
	if canvas_layer:
		shop_button = shop_button_scene.instantiate()
		shop_button.anchors_preset = 1  # Top right
		shop_button.anchor_left = 1.0
		shop_button.anchor_right = 1.0
		shop_button.offset_left = -58.0
		shop_button.offset_top = 10.0
		shop_button.offset_right = -10.0
		shop_button.offset_bottom = 58.0
		shop_button.grow_horizontal = 0
		canvas_layer.add_child(shop_button)
		print("Shop button added to UI")
	else:
		print("ERROR: No CanvasLayer found to attach the shop button")
		# Try to add to the root instead as fallback
		shop_button = shop_button_scene.instantiate()
		shop_button.position = Vector2(get_viewport().size.x - 58, 10)
		get_tree().root.add_child(shop_button)

func add_shop_scene() -> void:
	shop_instance = shop_scene.instantiate()
	get_tree().root.add_child(shop_instance)
	print("Shop scene added to game")

func connect_signals() -> void:
	if shop_button and shop_instance:
		# Disconnect any existing connections first
		if shop_button.is_connected("shop_opened", Callable(shop_instance, "open_shop")):
			shop_button.disconnect("shop_opened", Callable(shop_instance, "open_shop"))
			
		# Connect shop button to shop instance
		shop_button.connect("shop_opened", Callable(shop_instance, "open_shop"))
		print("Shop signals connected successfully")
	else:
		print("ERROR: Could not connect shop signals - button or shop instance missing") 
