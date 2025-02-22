extends Node2D

@export var min_float_height: float = 5   # Minimum height for the float
@export var max_float_height: float = 10   # Maximum height for the float
@export var min_float_speed: float = 1.0   # Minimum speed of float
@export var max_float_speed: float = 2.0   # Maximum speed of float

var tween: Tween
var original_position: Vector2
var float_height: float
var float_speed: float

func _ready():
	# Save the original position
	original_position = position
	
	# Randomize the float height and speed for each coin
	float_height = randf_range(min_float_height, max_float_height)
	float_speed = randf_range(min_float_speed, max_float_speed)
	
	tween = create_tween()
	_start_float()

func _start_float():
	# Create the smooth up-down floating effect with random values
	tween.tween_property(self, "position:y", original_position.y - float_height, float_speed)
	tween.tween_property(self, "position:y", original_position.y + float_height, float_speed)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()  # Infinite loop

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("coin_collected"):
		body.coin_collected(1)  # Call the coin_collected method on the player
		queue_free()  # Remove the coin after collection
