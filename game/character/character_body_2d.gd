extends CharacterBody2D

var facing_right = true
var coins := 0
var spawn_pos = Vector2.ZERO

var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0

var DISTANCE_SHIELD := 40
var weapons = ["sword", "bow", "shield"]

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 50.0
const SHOOT_COST := 20.0
const SWORD_COST := 40.0
const DOUBLE_JUMP_COST := 40.0
const BOW_COST := 25.0

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var bow_sprite

var can_double_jump := false
var jump_timer := 0.0
var recently_jumped := false
var weapon_counter := 0
var shield_body = null
var transitioning = false
var fade_rect = null
var has_gun = false
var has_bow = true

func _ready() -> void:
	add_to_group("player")
	spawn_pos = global_position
	
	progress_bar.max_value = 100
	progress_bar.value = 100
	health_bar.max_value = 100
	health_bar.value = 100
	
	var parent = get_parent()
	var shield_body_scene : PackedScene = preload("res://character/shield.tscn")
	var shield_body_instance = shield_body_scene.instantiate()
	shield_body_instance.name = "shield"
	parent.add_child(shield_body_instance)
	shield_body = parent.get_node_or_null("shield")
	
	var bow_sprite_scene:PackedScene = preload("res://character/bow.tscn")
	var bow_instance = bow_sprite_scene.instantiate()
	bow_instance.name = "bow"
	get_parent().add_child(bow_instance)
	bow_sprite = parent.get_node_or_null("bow")
	
	Global.weapon = "bow"
	weapon_counter = weapons.find("bow")
	
	setup_transition_layer()

	bow_sprite.visible = true

	



func setup_transition_layer():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "TransitionLayer"
	add_child(canvas_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	canvas_layer.add_child(fade_rect)
	
	get_viewport().size_changed.connect(update_fade_rect_size)
	update_fade_rect_size()



func update_fade_rect_size():
	if fade_rect:
		fade_rect.size = get_viewport_rect().size
		fade_rect.position = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Q:
				switch_to_weapon("sword")
			elif event.keycode == KEY_R:
				switch_to_weapon("bow")
				bow_sprite.visible = true
			elif event.keycode == KEY_C:
				switch_to_weapon("shield")



func update_bow_position_and_rotation():
	var centered_global_position = global_position
	centered_global_position.y -= 20
	centered_global_position.x += 9
	var mouse_pos = get_global_mouse_position()
	var direc_to_mouse = (mouse_pos - centered_global_position).normalized()
	var angle_radians = atan2(direc_to_mouse.y, direc_to_mouse.x)
	var bow_pos = centered_global_position + Vector2(cos(angle_radians), sin(angle_radians)) * DISTANCE_SHIELD
	bow_sprite.position = bow_pos
	if angle_radians:
		bow_sprite.rotation = angle_radians
		



func _physics_process(delta: float) -> void:
	if transitioning:
		return
		
	check_door_collision()

	if health_bar.value <= 0:
		game_over()
	
	
	var centered_global_position = global_position
	centered_global_position.y -= 20
	centered_global_position.x += 9
	var mouse_pos = get_global_mouse_position()
	var direc_to_mouse = (mouse_pos - centered_global_position).normalized()
	var angle_radians = atan2(direc_to_mouse.y, direc_to_mouse.x)
	var shield_pos = centered_global_position + Vector2(cos(angle_radians), sin(angle_radians)) * DISTANCE_SHIELD
	shield_body.position = shield_pos
	if angle_radians:
		shield_body.rotation = angle_radians
	
	if Global.weapon != 'shield':
		shield_body.visible = false
		Global.has_shield = false
	else:
		shield_body.visible = true
		Global.has_shield = true
		
		
		
	if Global.weapon == "bow":
		bow_sprite.visible = true
		update_bow_position_and_rotation()
	else:
		bow_sprite.visible = false


	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	
	if Global.weapon == 'sword':
		sprite_2d.animation = "sword"
	elif abs(velocity.x) > 1 and not Global.dead and velocity.y == 0:
		sprite_2d.animation = "running"
	elif is_on_floor():
		sprite_2d.animation = "default"
		
		
	if is_on_floor():
		can_double_jump = true
		recently_jumped = false
	
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite_2d.animation = "jumping"


	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			$Jump1.play()
			velocity.y = JUMP_VELOCITY

		elif can_double_jump and progress_bar.value >= DOUBLE_JUMP_COST:
			$Jump2.play()
			velocity.y = JUMP_VELOCITY * 1.1
			progress_bar.value -= DOUBLE_JUMP_COST
			can_double_jump = false
	
	
	
	
	if Input.is_action_just_pressed("ui_select"):
		if Global.weapon == 'gun' and has_gun:
			progress_bar.value -= SHOOT_COST
			$Shoot.play()
			Global.shoot = [true, global_position, facing_right]
			
		elif Global.weapon == 'bow' and has_bow and progress_bar.value >= BOW_COST:
			progress_bar.value -= BOW_COST
			$Shoot.play()
			centered_global_position = global_position
			centered_global_position.y -= 20
			centered_global_position.x += 9
			var mouse_pos_shoot_bow = get_global_mouse_position()
			var direc_to_mouse_shoot_bow = (mouse_pos - centered_global_position).normalized()
			Global.shoot = [true, bow_sprite.global_position, direc_to_mouse_shoot_bow]

		elif Global.weapon == 'sword':
			progress_bar.value -= SWORD_COST
			sprite_2d.animation = 'sword'
			var kill_radius: float = 70.0
			
			for node in get_parent().get_children():
				if node is Area2D and node.has_method("enemy_damage"):
					var direction = node.global_position - global_position
					var distance = direction.length()
					if distance < kill_radius:
						node.enemy_damage(50)


	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	if not Global.dead:
		move_and_slide()
		if velocity.x != 0:
			sprite_2d.flip_h = velocity.x < 0
			
	get_right_direc(direction)
	
	Global.player_position = global_position




func switch_to_weapon(weapon_name: String) -> void:
	if weapons.has(weapon_name):
		Global.weapon = weapon_name
		match weapon_name:
			'sword':
				weapon_counter = 0
			'bow':
				weapon_counter = 1
			'shield':
				weapon_counter = 2

		if weapon_name == "bow":
			bow_sprite.visible = true
			

		
		
func check_door_collision():
	var door = get_node_or_null("../Door")
	if door:
		var distance = global_position.distance_to(door.global_position)
		if distance < 50:
			print("Player near door! Distance: " + str(distance))
			transition_to_level("res://Level2.tscn")



func transition_to_level(next_scene_path: String):
	if transitioning or fade_rect == null:
		return
	transitioning = true
	update_fade_rect_size()
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file(next_scene_path)




func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

func player_damage(number):
	if is_invulnerable:
		return
	health_bar.value -= number
	var tween = create_tween()
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 1.0, 0.1)
	tween.tween_property($Sprite2D, "material:shader_parameter/amount", 0.0, 0.1)
	
	is_invulnerable = true
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false

func game_over() -> void:
	Global.dead = true
	Global.coins_collected = 0
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
	Global.dead = false

func coin_collected(num):
	coins += num
	Global.coins_collected = coins
	$CoinCollect.play()
	$"+1".visible = true
	$collect.start()

func _on_collect_timeout() -> void:
	$"+1".visible = false

func _on_barrel_2_explo_damage(num: Variant) -> void:
	player_damage(num)

func _on_barrel_3_explo_damage(num: Variant) -> void:
	player_damage(num)

func _on_barrel_explo_damage(num: Variant) -> void:
	player_damage(num)

func teleport_to_spawn():
	return spawn_pos
