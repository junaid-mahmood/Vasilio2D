extends CharacterBody2D

@export var move_distance := 100.0
@export var move_direction := Vector2.RIGHT
@export var speed := 50.0
@export var wait_time := 1.0

var start_position: Vector2
var end_position: Vector2
var moving_to_end := true
var timer := 0.0

func _ready():
	$Sprite2D.texture = load("res://platform.png")
	$Sprite2D.scale = Vector2(0.5, 0.5)  # Adjust scale as needed
	
	# Setup movement positions
	start_position = global_position
	end_position = start_position + (move_direction.normalized() * move_distance)

func _physics_process(delta):
	if timer > 0:
		timer -= delta
		return
		
	var target = end_position if moving_to_end else start_position
	var dir = (target - global_position).normalized()
	
	if global_position.distance_to(target) < 5:
		global_position = target
		moving_to_end = !moving_to_end
		timer = wait_time
	else:
		velocity = dir * speed
		move_and_slide() 