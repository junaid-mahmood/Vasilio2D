extends Control

var characters = ['classic', 'tarzan', 'scientist']
var counter := 0

func _process(delta: float) -> void:
	for char in characters:
		get_node("%s" % char).visible = false 

	get_node("%s" % characters[counter]).visible = true 
	if Input.is_action_just_pressed('ui_up'):
		Global.player = characters[counter]
		get_tree().change_scene_to_file("res://main.tscn")
		
		
	if characters[counter] == 'scientist':
		get_node("scientist").position.y += sin(Time.get_ticks_msec() / 200) * delta * 100
		



func _on_right_pressed() -> void:
	counter += 1
	if counter == 3:
		counter = 0


func _on_left_pressed() -> void:
	counter -= 1
	if counter == -1:
		counter = 1
