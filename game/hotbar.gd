extends Control

var is_tarzan_mode = false
var is_scientist_mode = false
var grid_tween = null

func _ready():
	print("Hotbar controller ready")
	set_process_input(true)
	
	var tarzan = get_node_or_null("/root/tarzan")
	if tarzan or get_node_or_null("../tarzan"):
		is_tarzan_mode = true
		print("Tarzan mode activated in hotbar")
		setup_tarzan_hotbar()
	
	var scientist = get_node_or_null("/root/teleport")
	if scientist or get_node_or_null("../teleport"):
		is_scientist_mode = true
		print("Scientist mode activated in hotbar")
		setup_scientist_hotbar()
	
	update_all_text()
	highlight_current_weapon()

func setup_tarzan_hotbar():
	print("Setting up Tarzan hotbar")
	
	var grid_container = get_node_or_null("GridContainer")
	if not grid_container:
		print("GridContainer not found in hotbar")
		return
	
	var button1 = grid_container.get_node_or_null("Button")
	var label1 = grid_container.get_node_or_null("Button/RichTextLabel")
	if button1 and label1:
		button1.icon = load("res://assets/sword.png")
		print("Set Button1 icon to sword.png")
	
	var button2 = grid_container.get_node_or_null("Button2")
	var label2 = grid_container.get_node_or_null("Button2/RichTextLabel2")
	if button2 and label2:
		button2.icon = load("res://assets/bow.png")
		label2.text = "F"
		print("Set Button2 icon to bow.png and label to F")
	
	var button3 = grid_container.get_node_or_null("Button3")
	if button3:
		button3.visible = false
		print("Hid Button3")

func setup_scientist_hotbar():
	print("Setting up Scientist hotbar")
	
	var grid_container = get_node_or_null("GridContainer")
	if not grid_container:
		print("GridContainer not found in hotbar")
		return
	
	grid_tween = create_tween()
	grid_tween.tween_property(grid_container, "rotation_degrees", 15, 0.5).set_ease(Tween.EASE_IN_OUT)
	grid_tween.tween_property(grid_container, "rotation_degrees", -15, 0.5).set_ease(Tween.EASE_IN_OUT)
	grid_tween.set_loops()
	
	grid_container.theme_override_constants.separation = 25
	
	var button1 = grid_container.get_node_or_null("Button")
	var label1 = grid_container.get_node_or_null("Button/RichTextLabel")
	if button1 and label1:
		button1.icon = load("res://assets/sword.png")
		button1.modulate = Color(0.2, 0.6, 1.0)
		button1.custom_minimum_size = Vector2(60, 60)
		label1.text = "Q"
		
		var glow = ColorRect.new()
		glow.name = "GlowEffect"
		glow.color = Color(0.2, 0.6, 1.0, 0.3)
		glow.size = Vector2(70, 70)
		glow.position = Vector2(-5, -5)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.z_index = -1
		button1.add_child(glow)
		
		print("Set Button1 icon for energy blast")
	
	var button2 = grid_container.get_node_or_null("Button2")
	var label2 = grid_container.get_node_or_null("Button2/RichTextLabel2")
	if button2 and label2:
		button2.icon = load("res://assets/bow.png")
		button2.modulate = Color(0.4, 0.8, 1.0)
		button2.custom_minimum_size = Vector2(60, 60)
		label2.text = "Space"
		
		var portal_effect = ColorRect.new()
		portal_effect.name = "PortalEffect"
		portal_effect.color = Color(0.4, 0.8, 1.0, 0.3)
		portal_effect.size = Vector2(70, 70)
		portal_effect.position = Vector2(-5, -5)
		portal_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portal_effect.z_index = -1
		button2.add_child(portal_effect)
		
		var portal_tween = create_tween()
		portal_tween.set_loops()
		portal_tween.tween_property(portal_effect, "color:a", 0.1, 1.0)
		portal_tween.tween_property(portal_effect, "color:a", 0.3, 1.0)
		
		print("Set Button2 icon for portal")
	
	var button3 = grid_container.get_node_or_null("Button3")
	var label3 = grid_container.get_node_or_null("Button3/RichTextLabel3")
	if button3 and label3:
		button3.visible = true
		button3.icon = load("res://assets/shieldbig.png")
		button3.modulate = Color(1.0, 0.5, 0.8)
		button3.custom_minimum_size = Vector2(60, 60)
		label3.text = "F"
		
		var quantum_effect = ColorRect.new()
		quantum_effect.name = "QuantumEffect"
		quantum_effect.color = Color(1.0, 0.5, 0.8, 0.3)
		quantum_effect.size = Vector2(70, 70)
		quantum_effect.position = Vector2(-5, -5)
		quantum_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quantum_effect.z_index = -1
		button3.add_child(quantum_effect)
		
		var special_indicator = ColorRect.new()
		special_indicator.name = "SpecialAbilityIndicator"
		special_indicator.color = Color(1.0, 0.5, 0.8, 0.5)
		special_indicator.size = Vector2(60, 60)
		special_indicator.position = Vector2(0, 0)
		special_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		special_indicator.visible = false
		button3.add_child(special_indicator)
		
		var cooldown_label = Label.new()
		cooldown_label.name = "CooldownLabel"
		cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown_label.size = Vector2(60, 60)
		cooldown_label.add_theme_font_size_override("font_size", 20)
		special_indicator.add_child(cooldown_label)
		
		button3.tooltip_text = "Quantum Acceleration (F): Temporarily enhances speed, jump height, and abilities"
		
		print("Set Button3 icon for quantum acceleration")
	
	add_cooldown_indicator(button1, "EnergyAttackCooldown")
	add_cooldown_indicator(button2, "PortalCooldown")

func add_cooldown_indicator(button, name):
	var cooldown = ColorRect.new()
	cooldown.name = name
	cooldown.color = Color(0, 0, 0, 0.5)
	cooldown.visible = false
	cooldown.size = Vector2(60, 60)
	cooldown.position = Vector2(0, 0)
	cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label = Label.new()
	label.name = "CooldownLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(60, 60)
	label.add_theme_font_size_override("font_size", 20)
	
	cooldown.add_child(label)
	button.add_child(cooldown)

func _process(delta):
	highlight_current_weapon()
	
	if is_tarzan_mode:
		if Input.is_action_just_pressed("switch"):
			update_text_for_key("Q")
			Global.weapon = "vine"
		if Input.is_action_just_pressed("end"):
			update_text_for_key("F")
	elif is_scientist_mode:
		if Input.is_action_just_pressed("switch"):
			update_text_for_key("Q")
		if Input.is_action_just_pressed("ui_accept"):
			update_text_for_key("Space")
		if Input.is_action_just_pressed("end"):
			update_text_for_key("F")
			activate_quantum_acceleration()
		
		update_scientist_cooldowns()
		update_global_quantum_values()
	else:
		if Input.is_action_just_pressed("switch"):
			update_text_for_key("Q")
			Global.weapon = "sword"
		if Input.is_action_just_pressed("end"):
			update_text_for_key("R")
			Global.weapon = "gun"
		if Input.is_action_just_pressed("start"):
			update_text_for_key("C")
			Global.weapon = "shield"

func activate_quantum_acceleration():
	var scientist = get_node_or_null("../teleport")
	if scientist and scientist.has_method("activate_quantum_acceleration"):
		scientist.activate_quantum_acceleration()
		
		var grid_container = get_node_or_null("GridContainer")
		if grid_container:
			var button3 = grid_container.get_node_or_null("Button3")
			if button3:
				var flash = ColorRect.new()
				flash.color = Color(1.0, 0.5, 0.8, 0.5)
				flash.size = Vector2(60, 60)
				flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
				button3.add_child(flash)
				
				var tween = create_tween()
				tween.tween_property(flash, "color:a", 0.0, 0.3)
				tween.tween_callback(flash.queue_free)

func update_global_quantum_values():
	var scientist = get_node_or_null("../teleport")
	if scientist and scientist.has_method("get_special_ability_state"):
		var state = scientist.get_special_ability_state()
		Global.quantum_acceleration_active = state.active
		Global.quantum_acceleration_cooldown = state.cooldown
		
		if Global.quantum_acceleration_max_cooldown != scientist.quantum_acceleration_cooldown_time:
			Global.quantum_acceleration_max_cooldown = scientist.quantum_acceleration_cooldown_time

func update_scientist_cooldowns():
	var grid_container = get_node_or_null("GridContainer")
	if not grid_container:
		return
		
	var button1 = grid_container.get_node_or_null("Button")
	var button2 = grid_container.get_node_or_null("Button2")
	var button3 = grid_container.get_node_or_null("Button3")
	
	if button1 and button2 and button3:
		var scientist = get_node_or_null("../teleport")
		if scientist:
			var energy_cooldown = button1.get_node_or_null("EnergyAttackCooldown")
			if energy_cooldown and scientist.attack_cooldown > 0:
				energy_cooldown.visible = true
				var label = energy_cooldown.get_node_or_null("CooldownLabel")
				if label:
					label.text = str(ceil(scientist.attack_cooldown))
			elif energy_cooldown:
				energy_cooldown.visible = false
			
			var portal_cooldown = button2.get_node_or_null("PortalCooldown")
			if portal_cooldown and not scientist.can_teleport_timer:
				portal_cooldown.visible = true
				var label = portal_cooldown.get_node_or_null("CooldownLabel")
				if label:
					label.text = str(ceil(scientist.teleport_cooldown))
			elif portal_cooldown:
				portal_cooldown.visible = false
			
			var special_indicator = button3.get_node_or_null("SpecialAbilityIndicator")
			if special_indicator:
				if scientist.has_method("get_special_ability_state"):
					var state = scientist.get_special_ability_state()
					if state.active:
						special_indicator.visible = true
						special_indicator.color = Color(1.0, 0.5, 0.8, 0.7)
						var label = special_indicator.get_node_or_null("CooldownLabel")
						if label:
							label.text = str(ceil(state.duration))
					elif state.cooldown > 0:
						special_indicator.visible = true
						special_indicator.color = Color(0.5, 0.5, 0.5, 0.5)
						var label = special_indicator.get_node_or_null("CooldownLabel")
						if label:
							label.text = str(ceil(state.cooldown))
					else:
						special_indicator.visible = false
						
				var quantum_effect = button3.get_node_or_null("QuantumEffect")
				if quantum_effect:
					if scientist.quantum_acceleration_active:
						quantum_effect.color = Color(1.0, 0.5, 0.8, 0.6)
						
						if not quantum_effect.has_meta("tween_active"):
							quantum_effect.set_meta("tween_active", true)
							var quantum_tween = create_tween()
							quantum_tween.tween_property(quantum_effect, "color:a", 0.3, 0.3)
							quantum_tween.tween_property(quantum_effect, "color:a", 0.6, 0.3)
					else:
						quantum_effect.color = Color(1.0, 0.5, 0.8, 0.3)
						quantum_effect.remove_meta("tween_active")

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
	elif is_scientist_mode:
		if label1:
			label1.text = "Q"
		if label2:
			label2.text = "Space"
		if label3:
			label3.visible = true
			label3.text = "F"
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
			if Global.weapon == "vine":
				label1.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		elif is_scientist_mode:
			label1.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0, 1))
			label2.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))
			label3.add_theme_color_override("font_color", Color(1.0, 0.5, 0.8, 1))
		else:
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
	elif key == "R" or key == "F" or key == "Space":
		if is_scientist_mode and key == "F":
			label = find_child("RichTextLabel3", true, false)
		else:
			label = find_child("RichTextLabel2", true, false)
	elif key == "C":
		label = find_child("RichTextLabel3", true, false)

	if label:
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(func(): reset_text(label, key))

func reset_text(label, key):
	if is_tarzan_mode and key == "R":
		label.text = "F"
	elif is_scientist_mode:
		if key == "R":
			label.text = "Space"
		elif key == "F" and label.name == "RichTextLabel3":
			label.text = "F"
	else:
		label.text = key

func _on_button_pressed():
	if is_tarzan_mode:
		Global.weapon = "vine"
		print("Tarzan weapon set to vine")
	elif is_scientist_mode:
		var scientist = get_node_or_null("../teleport")
		if scientist and scientist.has_method("energy_attack") and scientist.progress_bar.value >= scientist.ATTACK_COST and scientist.attack_cooldown <= 0:
			scientist.progress_bar.value -= scientist.ATTACK_COST
			scientist.energy_attack()
			scientist.attack_cooldown = scientist.attack_cooldown_time
	else:
		Global.weapon = "sword"

func _on_button_2_pressed():
	if is_tarzan_mode:
		var tarzan = get_node_or_null("../tarzan")
		if tarzan and tarzan.has_method("activate_special_ability"):
			print("Activating Tarzan's special ability")
			tarzan.activate_special_ability()
	elif is_scientist_mode:
		var scientist = get_node_or_null("../teleport")
		if scientist and scientist.has_method("create_portal") and scientist.progress_bar.value >= scientist.PORTAL_COST:
			if Global.portals < 2:
				Global.portals += 1
				scientist.progress_bar.value -= scientist.PORTAL_COST
				scientist.create_portal()
			else:
				print("Maximum portals reached")
	else:
		Global.weapon = "bow"

func _on_button_3_pressed():
	print("Button 3 pressed")
	if is_scientist_mode:
		var scientist = get_node_or_null("../teleport")
		if scientist and scientist.has_method("activate_quantum_acceleration"):
			print("Activating Scientist's quantum acceleration")
			scientist.activate_quantum_acceleration()
	elif not is_tarzan_mode:
		Global.weapon = "shield"
