extends Control


func _ready():
	set_process_input(true)
	update_all_text()
	highlight_current_weapon()


func _process(delta):
	highlight_current_weapon()
	

	if Input.is_key_pressed(KEY_Q):
		update_text_for_key("Q")
		Global.weapon = "hook"
	if Input.is_key_pressed(KEY_R):
		update_text_for_key("R")
		Global.weapon = "grapple"
	if Input.is_key_pressed(KEY_C):
		update_text_for_key("C")
		Global.weapon = "punch"

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
		label1.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label2.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label3.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		

		if Global.weapon == "hook":
			label1.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		elif Global.weapon == "grapple":
			label2.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		elif Global.weapon == "punch":
			label3.add_theme_color_override("font_color", Color(1, 1, 0, 1))

func update_text_for_key(key):
	var label = null
	
	if key == "Q":
		label = find_child("RichTextLabel", true, false)
	elif key == "R":
		label = find_child("RichTextLabel2", true, false)
	elif key == "C":
		label = find_child("RichTextLabel3", true, false)




func _on_button_pressed():
	Global.weapon = "hook"

func _on_button_2_pressed():
	Global.weapon = "grapple"

func _on_button_3_pressed():
	Global.weapon = "punch"
