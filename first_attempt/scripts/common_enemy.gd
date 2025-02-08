extends Area2D

var health := 3
var direction_x := 1
@export var speed := 30


func _on_area_entered(area):
	health -= 1
	$AnimatedSprite2D.animation = 'hurt'
	$hurt_timer.start()
	area.queue_free()


func _process(delta):
	_check_health()
	position.x += speed * direction_x * delta
	
	
func _check_health():
	if health <= 0:
		queue_free()

func _on_hurt_time_timeout() -> void:
	$AnimatedSprite2D.animation = 'idle'


func _on_body_entered(body: Node2D) -> void:
	if 'player_damage' in body:
		body.player_damage(34)


func _on_border_area_body_entered(body: Node2D) -> void:
	direction_x *= -1
	$AnimatedSprite2D.flip_h = direction_x == -1


func _on_right_cliff_body_exited(body: Node2D) -> void:
	_on_border_area_body_entered(body)
	
	

func _on_left_cliff_body_exited(body: Node2D) -> void:
	_on_border_area_body_entered(body)
