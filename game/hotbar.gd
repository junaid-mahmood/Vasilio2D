extends Control

func _ready():
	print("Hotbar controller ready")
	set_process_input(true)
	
	update_all_text()
	highlight_current_weapon()

func _process(delta):
	highlight_current_weapon()
	
	if Input.is_key_pressed(KEY_Q):
		update_text_for_key("Q")
		Global.weapon = "sword"
	if Input.is_key_pressed(KEY_R):
		update_text_for_key("R")
		Global.weapon = "gun"
	if Input.is_key_pressed(KEY_C):
		update_text_for_key("C")
		Global.weapon = "shield"

func update_all_text():
	var label1 = find_child("RichTextLabel", true, false)
	var label2 = find_child("RichTextLabel2", true, false)
	var label3 = find_child("RichTextLabel3", true, false)
	
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
		label1.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		label2.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		label3.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		
		if Global.weapon == "sword":
			label1.add_theme_color_override("default_color", Color(1, 1, 0, 1))
		elif Global.weapon == "gun":
			label2.add_theme_color_override("default_color", Color(1, 1, 0, 1))
		elif Global.weapon == "shield":
			label3.add_theme_color_override("default_color", Color(1, 1, 0, 1))

func update_text_for_key(key):
	var rich_text_label = null
	
	if key == "Q":
		if has_node("GridContainer/RichTextLabel"):
			rich_text_label = $GridContainer/RichTextLabel
		else:
			rich_text_label = find_child("RichTextLabel", true, false)
	elif key == "R":
		if has_node("GridContainer/RichTextLabel2"):
			rich_text_label = $GridContainer/RichTextLabel2
		else:
			rich_text_label = find_child("RichTextLabel2", true, false)
	elif key == "C":
		if has_node("GridContainer/RichTextLabel3"):
			rich_text_label = $GridContainer/RichTextLabel3
		else:
			rich_text_label = find_child("RichTextLabel3", true, false)

		
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(func(): reset_text(rich_text_label, key))

func reset_text(label, key):
	label.text = key
