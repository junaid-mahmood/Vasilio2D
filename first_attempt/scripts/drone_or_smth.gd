extends Area2D

var health := 3

@export var speed := 25
@export var marker1: Marker2D
@export var marker2: Marker2D
@onready var target = marker2

@export var if_in_radius := 80
@onready var player = get_tree().get_first_node_in_group('Player')

signal enemy_shoot(pos, player_pos)
var can_shoot := true

var forward := true

func ready():
	position = marker1.position

func get_target():
	if forward and position.distance_to(marker2.position) < 10 or\
	not forward and position.distance_to(marker1.position) < 10:
		forward = not forward
	
	if position.distance_to(player.position) < 80 and position.distance_to(player.position) > 40:
		target = player
	elif forward:
		target = marker2
	else:
		target = marker1

func _process(delta):
	_check_health()
	get_target()
	position += (target.position - position).normalized() * speed * delta
	if can_shoot and position.distance_to(player.position) < 80 and 20 < position.distance_to(player.position):
		enemy_shoot.emit(position, player.position)
		$shoot.start()
		can_shoot = false
		

	
	

func flip_drone():
	$AnimatedSprite2D.flip_h = not forward
	if  position.distance_to(player.position) < if_in_radius:
		$AnimatedSprite2D.flip_h = position.x > player.position.x

func _on_area_entered(area):
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($AnimatedSprite2D, "material:shader_parameter/amount", 0.0, 0.1)
	health -= 1
	area.queue_free()

func _check_health():
	if health <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if 'player_damage' in body:
		body.player_damage(34)


func _on_shoot_timeout() -> void:
	can_shoot = true
