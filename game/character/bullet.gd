extends Area2D

var direction:int = 1  
@export var speed := 1000

func _process(delta):
	position.x += speed * direction * delta


func _ready():
	$Sprite2D.flip_h = direction < 0


func _on_body_entered(body: Node2D) -> void:
	queue_free()
