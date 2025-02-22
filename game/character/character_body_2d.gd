extends CharacterBody2D

<<<<<<< Updated upstream
=======
signal shoot(pos, bool)
signal barrel_inventory_changed(has_barrel)
var facing_right = true
var coins := 0
var is_invulnerable := false
const INVULNERABILITY_TIME := 1.0
var barrel_in_inventory := false

signal player_pos(pos)
signal new_coin(coins)

>>>>>>> Stashed changes
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 3000.0
const FRICTION = 2000.0
const RECHARGE_RATE := 50.0 
const SHOOT_COST := 20.0
const DOUBLE_JUMP_COST := 40.0
const BARREL_PICKUP_RANGE := 75.0
const BARREL_HEALTH := 15
const HEART_DROP_CHANCE := 0.3
const HEALTH_RESTORE_AMOUNT := 20.0

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = get_node("../CanvasLayer/JumpBar")
<<<<<<< Updated upstream
@onready var particles: CPUParticles2D = $CPUParticles2D
=======
@onready var health_bar: ProgressBar = get_node("../CanvasLayer/HealthBar")
@onready var hotbar = get_node_or_null("../CanvasLayer/hotbar")
@onready var bow_notification = $bow
@onready var heart_scene = $heart
@onready var plus_one = $"+1"
>>>>>>> Stashed changes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump := false
var nearest_pickable_barrel = null
var nearest_heart = null
var has_unlocked_bow := false
var can_pickup_heart := true

func _ready() -> void:
	progress_bar.max_value = 100
	progress_bar.value = 100
<<<<<<< Updated upstream

func shoot_particles() -> void:
	if progress_bar.value >= SHOOT_COST and particles:
		progress_bar.value -= SHOOT_COST
		particles.position = sprite_2d.position + Vector2(0, -16)
		particles.direction = Vector2(-1, 0) if sprite_2d.flip_h else Vector2(1, 0)
		particles.restart()
		particles.emitting = true

func _physics_process(delta: float) -> void:
	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	if abs(velocity.x) > 1:
		sprite_2d.animation = "running"
	else:
		sprite_2d.animation = "default"
=======
	health_bar.max_value = 100
	health_bar.value = 100
	
	if heart_scene:
		heart_scene.visible = false
	
	if bow_notification and bow_notification.visible:
		bow_notification.visible = false
	
	Global.weapon = false
	
	if hotbar:
		var sword_slot = hotbar.get_node_or_null("GridContainer/Button")
		var sword_key = hotbar.get_node_or_null("GridContainer/Button/Label")
		if sword_slot:
			sword_slot.visible = true
			if sword_key:
				sword_key.text = "E"
				sword_key.visible = true
		
		var bow_slot = hotbar.get_node_or_null("GridContainer/Button2")
		if bow_slot:
			bow_slot.visible = false
		
		var barrel_slot = hotbar.get_node_or_null("GridContainer/Button3")
		if barrel_slot:
			barrel_slot.visible = false

	for node in get_tree().get_nodes_in_group("barrel"):
		if not "health" in node:
			node.set("health", BARREL_HEALTH)
	
	for node in get_parent().get_children():
		if node is Area2D and "explosion" in node:
			if not "health" in node:
				node.set("health", BARREL_HEALTH)

func _physics_process(delta: float) -> void:
	if health_bar.value <= 0:
		game_over()
		
	if Input.is_action_just_pressed("switch"):
		if has_unlocked_bow:
			Global.weapon = not Global.weapon
		else:
			Global.weapon = false
	
	if not barrel_in_inventory:
		find_nearest_barrel()
	else:
		nearest_pickable_barrel = null
	
	# Find and handle heart pickup
	find_nearest_heart()
	if nearest_heart and can_pickup_heart and health_bar.value < health_bar.max_value:
		pickup_heart(nearest_heart)
	
	if Input.is_key_pressed(KEY_E) and not barrel_in_inventory and nearest_pickable_barrel != null:
		pickup_barrel(nearest_pickable_barrel)
	
	if Input.is_key_pressed(KEY_R) and barrel_in_inventory:
		use_barrel_from_inventory()
	
	if progress_bar.value < 100:
		progress_bar.value = min(progress_bar.value + RECHARGE_RATE * delta, 100)
	
	handle_animation()
>>>>>>> Stashed changes
		
	if is_on_floor():
		can_double_jump = true
	
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite_2d.animation = "jumping"

	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif can_double_jump and progress_bar.value >= DOUBLE_JUMP_COST:
			velocity.y = JUMP_VELOCITY * 1.1
			progress_bar.value -= DOUBLE_JUMP_COST
<<<<<<< Updated upstream
			can_double_jump = false  # Prevent additional double jumps until landing

	if Input.is_action_just_pressed("ui_select"):
		shoot_particles()
=======
			can_double_jump = false

	handle_attack()
>>>>>>> Stashed changes

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if (direction < 0 and velocity.x > 0) or (direction > 0 and velocity.x < 0):
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 2)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	move_and_slide()
	
	if velocity.x != 0:
		sprite_2d.flip_h = velocity.x < 0
<<<<<<< Updated upstream
=======
		
	emit_signal("player_pos", position)

func find_nearest_heart():
	nearest_heart = null
	var nearest_distance = BARREL_PICKUP_RANGE
	
	for node in get_parent().get_children():
		if node.is_in_group("heart"):
			var direction = node.global_position - global_position
			var distance = direction.length()
			if distance < nearest_distance:
				nearest_heart = node
				nearest_distance = distance

func pickup_heart(heart):
	if heart and can_pickup_heart and health_bar.value < health_bar.max_value:
		can_pickup_heart = false
		
		if plus_one:
			plus_one.text = "+20%"
			plus_one.visible = true
			plus_one.position = Vector2(0, -40)
			
			var heart_timer = Timer.new()
			heart_timer.name = "HeartTimer"
			heart_timer.wait_time = 2.0
			heart_timer.one_shot = true
			add_child(heart_timer)
			heart_timer.connect("timeout", Callable(self, "_on_heart_timer_timeout"))
			heart_timer.start()
		
		heal(HEALTH_RESTORE_AMOUNT)
		heart.queue_free()

func _on_heart_timer_timeout():
	if plus_one:
		plus_one.visible = false
	can_pickup_heart = true

func handle_animation():
	if barrel_in_inventory:
		sprite_2d.animation = "default"
	elif Global.weapon and has_unlocked_bow:
		sprite_2d.animation = "bow"
		sprite_2d.frame = 0
	elif Global.weapon == false:
		sprite_2d.animation = "sword"
		sprite_2d.frame = 0
	elif abs(velocity.x) > 1:
		sprite_2d.animation = "running"
	else:
		sprite_2d.animation = "default"

func handle_attack():
	if Input.is_action_just_pressed("ui_select"):
		if not barrel_in_inventory:
			if Global.weapon and has_unlocked_bow:
				progress_bar.value -= SHOOT_COST
				shoot.emit(global_position, facing_right)
				sprite_2d.animation = "bow"
				sprite_2d.frame = 0
			else:
				progress_bar.value -= SWORD_COST
				sprite_2d.animation = "sword"
				sprite_2d.frame = 0
				var kill_radius: float = 70.0   
				
				for node in get_parent().get_children():
					if node is Area2D and "explosion" in node:
						var direction = node.global_position - global_position
						var distance = direction.length()
						if distance < kill_radius:
							if "health" in node:
								node.health -= 50
								if node.health <= 0:
									handle_barrel_destruction(node.global_position)
									node.queue_free()
							else:
								handle_barrel_destruction(node.global_position)
								node.queue_free()
					
					elif node is Area2D and node.has_method("enemy_damage"):
						var direction = node.global_position - global_position
						var distance = direction.length()
						if distance < kill_radius:
							node.enemy_damage(50)

func handle_barrel_destruction(pos: Vector2):
	if randf() < HEART_DROP_CHANCE and health_bar.value < health_bar.max_value:
		var heart = heart_scene.duplicate()
		heart.position = pos
		heart.visible = true
		heart.add_to_group("heart")
		get_parent().add_child(heart)
		print("Heart spawned at position: ", pos)
	
	if not has_unlocked_bow and randf() < 0.3:
		unlock_bow()

func get_right_direc(direction):
	if direction != 0:
		facing_right = direction >= 0

func find_nearest_barrel():
	nearest_pickable_barrel = null
	var nearest_distance = BARREL_PICKUP_RANGE
	
	for node in get_parent().get_children():
		if node is Area2D and "explosion" in node:
			var direction = node.global_position - global_position
			var distance = direction.length()
			if distance < nearest_distance:
				nearest_pickable_barrel = node
				nearest_distance = distance

func pickup_barrel(barrel):
	if barrel:
		barrel_in_inventory = true
		barrel.queue_free()
		
		if hotbar:
			var barrel_slot = hotbar.get_node_or_null("GridContainer/Button3")
			var barrel_key = hotbar.get_node_or_null("GridContainer/Button3/Label3")
			if barrel_slot:
				barrel_slot.visible = true
				if barrel_key:
					barrel_key.text = "R"
					barrel_key.visible = true
		
		emit_signal("barrel_inventory_changed", true)

func use_barrel_from_inventory():
	if barrel_in_inventory:
		if "explosion" in get_parent().get_children()[0]:
			var explosion_scene = load(get_parent().get_children()[0].explosion.resource_path)
			var explosion_instance = explosion_scene.instantiate()
			explosion_instance.position = global_position
			explosion_instance.rotation = global_rotation
			explosion_instance.emitting = true
			get_tree().current_scene.add_child(explosion_instance)
			
			var explosion_radius = 100.0
			for node in get_parent().get_children():
				if node is Area2D and node.has_method("enemy_damage"):
					var direction = node.global_position - global_position
					var distance = direction.length()
					if distance < explosion_radius:
						node.enemy_damage(30)
		
		velocity.y = JUMP_VELOCITY * 1.5
		velocity.x += 200 * (1 if facing_right else -1)
		
		barrel_in_inventory = false
		
		if hotbar:
			var barrel_slot = hotbar.get_node_or_null("GridContainer/Button3")
			if barrel_slot:
				barrel_slot.visible = false
		
		handle_barrel_destruction(global_position)
		emit_signal("barrel_inventory_changed", false)

func unlock_bow():
	has_unlocked_bow = true
	
	if has_node("+1"):
		$"+1".visible = false
	
	if bow_notification:
		bow_notification.position = Vector2(0, -40)
		bow_notification.visible = true
		
		var bow_timer = Timer.new()
		bow_timer.name = "BowTimer"
		bow_timer.wait_time = 2.0
		bow_timer.one_shot = true
		add_child(bow_timer)
		bow_timer.connect("timeout", Callable(self, "_on_bow_timer_timeout"))
		bow_timer.start()
	
	if hotbar:
		var bow_slot = hotbar.get_node_or_null("GridContainer/Button2")
		var bow_key = hotbar.get_node_or_null("GridContainer/Button2/Label2")
		if bow_slot:
			bow_slot.visible = true
			if bow_key:
				bow_key.text = "Q" 
				bow_key.visible = true

func _on_bow_timer_timeout():
	if bow_notification:
		bow_notification.visible = false

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

func heal(percent: float):
	var heal_amount = health_bar.max_value * (percent / 100.0)
	health_bar.value = min(health_bar.value + heal_amount, health_bar.max_value)
	print("Healed for ", heal_amount, " health")

func game_over() -> void:
	get_tree().reload_current_scene()

func coin_collected(num):
	coins += num
	emit_signal("new_coin", coins)
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
>>>>>>> Stashed changes
