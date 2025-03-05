extends Area2D

var has_printed = false
var is_active = false
var is_transitioning = false
var next_scene_path = "res://level2.tscn"

func _ready():
	connect("body_entered", Callable(self, "_on_Door_body_entered"))
	print("Door ready - waiting for player")
	
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	is_active = true

func _on_Door_body_entered(body):
	if is_active and not has_printed and not is_transitioning and (body.name == "Player" or body is CharacterBody2D):
		trigger_transition()

func _physics_process(_delta):
	if not is_active or is_transitioning:
		return
		
	var bodies = get_overlapping_bodies()
	var player_touching = false
	
	for body in bodies:
		if body.name == "Player" or body is CharacterBody2D:
			player_touching = true
			break
	
	if player_touching and not has_printed:
		trigger_transition()
	elif not player_touching:
		has_printed = false

func trigger_transition():
	if is_transitioning:
		return
		
	is_transitioning = true
	has_printed = true
	print("Player has touched the door!")
	
	var transition = TransitionLayer.new(next_scene_path)
	get_tree().root.add_child(transition)
	transition.start_transition()

class TransitionLayer extends CanvasLayer:
	var target_scene
	var color_rect
	
	func _init(scene_path):
		layer = 100
		target_scene = scene_path
		
	func _ready():
		color_rect = ColorRect.new()
		color_rect.color = Color(0, 0, 0, 0)  
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)  
		add_child(color_rect)
	
	func start_transition():
		# Fade out animation
		var tween = create_tween()
		tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), 0.5)  
		tween.tween_callback(self.change_scene)
		
	func change_scene():
		print("Changing to next level...")
		
		var err = get_tree().change_scene_to_file(target_scene)
		if err != OK:
			err = get_tree().change_scene_to_file("res://levels/" + target_scene.get_file())
			if err != OK:
				print("Error loading level, using reload as fallback")
				get_tree().reload_current_scene()
		
		var fade_in_timer = Timer.new()
		add_child(fade_in_timer)
		fade_in_timer.wait_time = 0.2
		fade_in_timer.one_shot = true
		fade_in_timer.connect("timeout", Callable(self, "fade_in"))
		fade_in_timer.start()
	
	func fade_in():
		var tween = create_tween()
		tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), 0.5)  
		tween.tween_callback(self.queue_free) 
