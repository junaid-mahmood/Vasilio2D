extends Control

var characters = ['classic', 'tarzan', 'scientist']
var counter := 0

func _process(delta: float) -> void:
	# Hide all characters first
	for char in characters:
		var node = get_node_or_null("%s" % char)
		if node:
			node.visible = false 

	# Show only the selected character
	var selected_char = get_node_or_null("%s" % characters[counter])
	if selected_char:
		selected_char.visible = true 
		
	# Change scene when up is pressed
	if Input.is_action_just_pressed('ui_up'):
		Global.player = characters[counter]
		get_tree().change_scene_to_file("res://main.tscn")
		
	# Special animation for scientist character
	if characters[counter] == 'scientist':
		var scientist_node = get_node_or_null("scientist")
		if scientist_node:
			scientist_node.position.y += sin(Time.get_ticks_msec() / 200) * delta * 100

func _on_right_pressed() -> void:
	counter += 1
	if counter == 3:
		counter = 0

func _on_left_pressed() -> void:
	counter -= 1
	if counter == -1:
		counter = 1
