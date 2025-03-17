extends Control

var is_tarzan_mode = false

func _ready():
	print("Hotbar controller ready")
	set_process_input(true)
	
	# Check if we're in a Tarzan scene
	var tarzan = get_node_or_null("/root/tarzan")
	if tarzan or get_node_or_null("../tarzan"):
		is_tarzan_mode = true
		print("Tarzan mode activated in hotbar")
		setup_tarzan_hotbar()
	
	update_all_text()
	highlight_current_weapon()

func setup_tarzan_hotbar():
	print("Setting up Tarzan hotbar")
	
	# Get the grid container
	var grid_container = get_node_or_null("GridContainer")
	if not grid_container:
		print("GridContainer not found in hotbar")
		return
	
	# Configure first button (Q) for Tarzan's vine attack
	var button1 = grid_container.get_node_or_null("Button")
	var label1 = grid_container.get_node_or_null("Button/RichTextLabel")
	if button1 and label1:
		# Use a vine-like icon for Tarzan's attack
		button1.icon = load("res://assets/sword.png")
		print("Set Button1 icon to sword.png")
	
	# Configure second button (F) for Tarzan's special ability
	var button2 = grid_container.get_node_or_null("Button2")
	var label2 = grid_container.get_node_or_null("Button2/RichTextLabel2")
	if button2 and label2:
		# Use a special ability icon
		button2.icon = load("res://assets/bow.png")
		label2.text = "F"
		print("Set Button2 icon to bow.png and label to F")
	
	# Hide the third button (C) as Tarzan doesn't use it
	var button3 = grid_container.get_node_or_null("Button3")
	if button3:
		button3.visible = false
		print("Hid Button3")

func _process(delta):
	highlight_current_weapon()
	
	if is_tarzan_mode:
		# Tarzan-specific controls
		if Input.is_key_pressed(KEY_Q):
			update_text_for_key("Q")
			Global.weapon = "vine"
		if Input.is_key_pressed(KEY_F):
			update_text_for_key("F")
			# Special ability is handled by Tarzan script
	else:
		# Regular character controls
		if Input.is_key_pressed(KEY_Q):
			update_text_for_key("Q")
			Global.weapon = "sword"
		if Input.is_key_pressed(KEY_R):
			update_text_for_key("R")
			Global.weapon = "bow"
		if Input.is_key_pressed(KEY_C):
			update_text_for_key("C")
			Global.weapon = "shield"

func update_all_text():
	var label1 = find_child("RichTextLabel", true, false)
	var label2 = find_child("RichTextLabel2", true, false)
	var label3 = find_child("RichTextLabel3", true, false)
	
	if is_tarzan_mode:
		if label1:
			label1.text = "Q"
		if label2:
			label2.text = "F"
		if label3:
			label3.visible = false
	else:
		if label1:
			label1.text = "Q"
		if label2:
			label2.text = "R"
		if label3:
			label3.text = "C"

func highlight_current_weapon():
	var label1 = find_child("RichTextLabel", true, false)
	var label2 = find_child("RichTextLabel2", true, false)
	var label3 = find_child("RichTextLabel3", true, false)
	
	if label1 and label2 and label3:
		label1.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label2.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label3.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		
		if is_tarzan_mode:
			# Tarzan's weapons
			if Global.weapon == "vine":
				label1.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		else:
			# Regular weapons
			if Global.weapon == "sword":
				label1.add_theme_color_override("font_color", Color(1, 1, 0, 1))
			elif Global.weapon == "bow":
				label2.add_theme_color_override("font_color", Color(1, 1, 0, 1))
			elif Global.weapon == "shield":
				label3.add_theme_color_override("font_color", Color(1, 1, 0, 1))

func update_text_for_key(key):
	var label = null
	
	if key == "Q":
		label = find_child("RichTextLabel", true, false)
	elif key == "R" or key == "F":
		label = find_child("RichTextLabel2", true, false)
	elif key == "C":
		label = find_child("RichTextLabel3", true, false)

	if label:
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(func(): reset_text(label, key))

func reset_text(label, key):
	if is_tarzan_mode and key == "R":
		label.text = "F"
	else:
		label.text = key

func _on_button_pressed():
	if is_tarzan_mode:
		Global.weapon = "vine"
	else:
		Global.weapon = "sword"

func _on_button_2_pressed():
	if is_tarzan_mode:
		# Trigger Tarzan's special ability
		var tarzan = get_node_or_null("/root/tarzan")
		if not tarzan:
			tarzan = get_node_or_null("../tarzan")
		
		if tarzan and tarzan.has_method("activate_special_ability"):
			print("Activating Tarzan's special ability")
			tarzan.activate_special_ability()
	else:
		Global.weapon = "bow"

func _on_button_3_pressed():
	if not is_tarzan_mode:
		Global.weapon = "shield"
