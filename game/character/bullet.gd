extends Area2D

var direction:int = 1  
@export var speed := 1000

func _process(delta):
	position.x += speed * direction * delta


func _ready():
	$Sprite2D.flip_h = direction < 0


func _on_body_entered(body: Node2D) -> void:
	if body.has_method('im_jungle_enemy'):
		body.enemy_damage(10)
	queue_free()

func _this_is_bullet():
	pass
