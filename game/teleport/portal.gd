extends Area2D

@export var speed: float = 1000
var velocity: Vector2 = Vector2.ZERO
var start_pos = Vector2.ZERO
var set_pos = Vector2.ZERO

func _ready() -> void:
	start_pos = global_position

func _process(delta):
	if set_pos != Global.portal1 and set_pos != Global.portal2 and velocity == Vector2.ZERO:
		queue_free()
	position += velocity * delta



func _on_body_entered(body: Node2D) -> void:
	velocity = Vector2.ZERO
	
	
	var direction = (start_pos - global_position).normalized() 
	global_position += direction * 10
	$Sprite2D.animation = "portal"
