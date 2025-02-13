extends Area2D

@export var speed: float = 300
var velocity: Vector2 = Vector2.ZERO


func _process(delta):
	position += velocity * delta



func _on_body_entered(body: Node2D) -> void:
	if 'player_damage' in body:
		body.player_damage(30)
