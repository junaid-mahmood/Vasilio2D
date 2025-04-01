extends Node

const bullet_scene: PackedScene = preload("res://character/bullet.tscn")
const enemy_bullet_scene: PackedScene = preload("res://enemy/enemy_bullet.tscn")
const portal_bullet_scene: PackedScene = preload("res://teleport/portal.tscn")
const bow_bullet_scene: PackedScene = preload("res://bow/bow_bullet.tscn")
const teleport_hotbar: PackedScene = preload("res://hotbar_teleport.tscn")
const tarzan_hotbar: PackedScene = preload("res://hotbar_tarzan.tscn")
const classic_hotbar: PackedScene = preload("res://hotbar.tscn")

var player_character
var music_player: AudioStreamPlayer
var required_coins := 1  # Set to 1 for debugging
var celebration_shown := false

@export var interact_distance: float = 50.0

func _ready() -> void:
	stop_all_audio()
	music_player = $AudioStreamPlayer
	setup_music()
	
	var hotbar_instance
	var canvas
	canvas = get_node("CanvasLayer")
	
	if Global.player == 'tarzan':
		player_character = load("res://tarzan/tarzan.tscn").instantiate() 
		player_character.position = Vector2(110.0, -20.0)
		hotbar_instance = tarzan_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
		
	elif Global.player == 'classic':
		player_character = load("res://character/character_body_2d.tscn").instantiate()
		player_character.position = Vector2(110.0, -20.0)
		hotbar_instance = classic_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
		
	elif Global.player == 'scientist':
		player_character = load("res://teleport/teleport.tscn").instantiate()
		player_character.position = Vector2(110.0, -20.0)
		hotbar_instance = teleport_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
	
	canvas.add_child(hotbar_instance)
	
	add_child(player_character)
	Vector2(110.0, -6.0)
	
	play_music()

func setup_music() -> void:
	music_player.stream = load("res://mainlv3.mp3")
	music_player.volume_db = -15.0
	music_player.mix_target = AudioStreamPlayer.MIX_TARGET_SURROUND
	
	if not music_player.is_in_group("audio_players"):
		music_player.add_to_group("audio_players")

func play_music() -> void:
	if music_player and not music_player.playing:
		music_player.play()

func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()
		
func stop_all_audio() -> void:
	var audio_nodes = get_tree().get_nodes_in_group("audio_players")
	for audio_node in audio_nodes:
		if audio_node is AudioStreamPlayer and audio_node.playing:
			audio_node.stop()

func _process(delta: float) -> void:
	if Global.shoot[0]:
		if Global.weapon == 'bow':
			var bow_bullet = bow_bullet_scene.instantiate()
			var direc_bow = Global.shoot[2]
			var spawn_pos = Global.shoot[1]
		
			bow_bullet.position = spawn_pos
			bow_bullet.velocity = direc_bow * bow_bullet.speed
			bow_bullet.rotation = direc_bow.angle()
	
			$Bullets.add_child(bow_bullet)
			Global.shoot[0] = false
			
		else:
			var pos = Global.shoot[1]
			var facing_right = Global.shoot[2]
			var bullet = bullet_scene.instantiate()
			var direction = 1 if facing_right else -1
			bullet.direction = direction
			$Bullets.add_child(bullet)
			pos.y -= 20
			bullet.position = pos + Vector2(6 * direction, 0)
			Global.shoot[0] = false
		
	if Global.enemy_shoot[0]:
		var pos = Global.enemy_shoot[1]
		var player_pos = Global.enemy_shoot[2]
		
		var en_bullet = enemy_bullet_scene.instantiate()		
		pos.y -= 20
		en_bullet.position = pos
		var direction: Vector2 = (player_pos - pos).normalized()
		en_bullet.velocity = direction * en_bullet.speed
		en_bullet.rotation = direction.angle()
		$EnemyBullets.add_child(en_bullet)
		Global.enemy_shoot[0] = false

	if Global.shoot_portal[0]:
		await get_tree().create_timer(1)
		var pos = Global.shoot_portal[1]
		var portal_bullet = portal_bullet_scene.instantiate()
		var direction := Vector2.ZERO
		if Global.portals == 1:
			direction = (Global.portal1 - pos).normalized()
			
		elif Global.portals == 2:
			direction = (Global.portal2 - pos).normalized()
		
		portal_bullet.position = pos
		portal_bullet.velocity = direction * portal_bullet.speed
		portal_bullet.rotation = direction.angle()
		if Global.portals == 1:
			portal_bullet.set_pos = Global.portal1
		else:
			portal_bullet.set_pos = Global.portal2
		$EnemyBullets.add_child(portal_bullet)
		Global.shoot_portal[0] = false
	
	if Input.is_action_just_pressed("start"):
		var nearest_torch = get_nearest_torch()
		if nearest_torch:
			nearest_torch.toggle_torch()

	# Get required coins for level 3 from global configuration
	var required_coins = Global.coins_required["res://level_3.tscn"]
	
	# Check if all required coins are collected and celebration hasn't been shown yet
	if Global.coins_collected >= required_coins and not celebration_shown:
		show_celebration()
		celebration_shown = true

func _exit_tree() -> void:
	stop_music()
		
		
func get_nearest_torch():
	var player = get_tree().get_first_node_in_group("player")
	var nearest: Node2D = null
	var nearest_dist = interact_distance
	for torch in get_tree().get_nodes_in_group("torches"):
		var distance = player.global_position.distance_to(torch.global_position)
		if distance < nearest_dist:
			nearest = torch
			nearest_dist = distance
	return nearest

func show_celebration():
	# Lock player movement by setting Global.dead to true
	Global.dead = true
	
	# Create a dark overlay background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	
	# Create canvas layer for celebration elements
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(background)
	
	# Make background fill screen
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Create the celebration sprite
	var celebration_sprite = Sprite2D.new()
	celebration_sprite.texture = load("res://vas.png")
	
	# Center the sprite
	var viewport_size = get_viewport().get_visible_rect().size
	celebration_sprite.position = viewport_size / 2
	canvas_layer.add_child(celebration_sprite)
	
	# Create particle effects
	var particles = GPUParticles2D.new()
	var particle_material = ParticleProcessMaterial.new()
	
	# Configure particle material
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 50.0
	particle_material.particle_flag_disable_z = true
	particle_material.gravity = Vector3(0, 98, 0)
	particle_material.initial_velocity_min = 100.0
	particle_material.initial_velocity_max = 200.0
	particle_material.scale_min = 4.0
	particle_material.scale_max = 8.0
	particle_material.color = Color(1, 0.8, 0.2, 1)  # Golden color
	
	# Configure particles
	particles.process_material = particle_material
	particles.amount = 50
	particles.lifetime = 2.0
	particles.explosiveness = 0.5
	particles.randomness = 0.5
	particles.position = viewport_size / 2
	particles.emitting = true
	canvas_layer.add_child(particles)
	
	# Create return to title button
	var button = Button.new()
	button.text = "Return to Title Screen"
	button.custom_minimum_size = Vector2(200, 50)  # Set minimum size
	button.position = Vector2(
		viewport_size.x / 2 - button.custom_minimum_size.x / 2,
		viewport_size.y * 0.7
	)
	
	# Style the button
	var button_theme = Theme.new()
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.8, 1)  # Blue color
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", button_style)
	
	# Connect button press to return to title
	button.pressed.connect(func():
		# Reset any necessary game state
		Global.dead = false
		Global.coins_collected = 0
		get_tree().change_scene_to_file("res://title.tscn")
	)
	
	canvas_layer.add_child(button)
	
	# Add to scene
	add_child(canvas_layer)
