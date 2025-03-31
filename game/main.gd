extends Node

const bullet_scene: PackedScene = preload("res://character/bullet.tscn")
const enemy_bullet_scene: PackedScene = preload("res://enemy/enemy_bullet.tscn")
const portal_bullet_scene: PackedScene = preload("res://teleport/portal.tscn")
const bow_bullet_scene: PackedScene = preload("res://bow/bow_bullet.tscn")

const teleport_hotbar: PackedScene = preload("res://hotbar_teleport.tscn")
const tarzan_hotbar: PackedScene = preload("res://hotbar_tarzan.tscn")
const classic_hotbar: PackedScene = preload("res://hotbar.tscn")

var player_character
var quantum_effect_active := false
var quantum_particles := []
var music_player: AudioStreamPlayer
var fade_rect = null
var transitioning = false

func _ready() -> void:
	stop_all_audio()
	music_player = $AudioStreamPlayer
	setup_music()
	var hotbar_instance
	var canvas
	canvas = get_node("CanvasLayer")
	if Global.player == 'tarzan':
		player_character = load("res://tarzan/tarzan.tscn").instantiate() 
		player_character.position = Vector2(79, 600)
		hotbar_instance = tarzan_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
		
		
		
	elif Global.player == 'classic':
		player_character = load("res://character/character_body_2d.tscn").instantiate()
		player_character.position = Vector2(79, 611)
		hotbar_instance = classic_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
		
		
	elif Global.player == 'scientist':
		player_character = load("res://teleport/teleport.tscn").instantiate()
		player_character.position = Vector2(79, 600)
		hotbar_instance = teleport_hotbar.instantiate()
		hotbar_instance.name = 'hotbar'
	
	canvas.add_child(hotbar_instance)
	add_child(player_character)
	
	# Initialize the transition layer
	setup_transition_layer()
	
	play_music()

func setup_music() -> void:
	music_player.stream = load("res://mainlv1.mp3")
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
		var weapon_str = str(Global.weapon)

		if weapon_str == 'bow':
			var bow_bullet = bow_bullet_scene.instantiate()
			var direc_bow = Global.shoot[2] if typeof(Global.shoot[2]) == TYPE_VECTOR2 else Vector2.RIGHT
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
		await get_tree().create_timer(0.1).timeout
		
		var pos = Global.shoot_portal[1]
		var portal_bullet = portal_bullet_scene.instantiate()
		var direction := Vector2.ZERO
		
		if Global.portals == 1:
			direction = (Global.portal1 - pos).normalized()
			portal_bullet.portal_number = 1
		elif Global.portals == 2:
			direction = (Global.portal2 - pos).normalized()
		
		portal_bullet.position = pos
		portal_bullet.velocity = direction * portal_bullet.speed
		portal_bullet.rotation = direction.angle()
		
		if Global.portals == 1:
			portal_bullet.set_pos = Global.portal1
		else:
			portal_bullet.set_pos = Global.portal2
		
		if has_node("Portals"):
			$Portals.add_child(portal_bullet)
		else:
			$EnemyBullets.add_child(portal_bullet)
		
		Global.shoot_portal[0] = false
		
	if Global.level_changed:
		if player_character and player_character.has_method("_on_level_changed"):
			player_character._on_level_changed()
		Global.level_changed = false
		
	if quantum_effect_active:
		update_quantum_world_effects(delta)

func _exit_tree() -> void:
	stop_music()

func _check_quantum_state():
	if Global.player == 'scientist' and player_character and player_character.has_method("get_special_ability_state"):
		var ability_state = player_character.get_special_ability_state()
		
		if ability_state.active and not quantum_effect_active:
			quantum_effect_active = true
			create_quantum_world_effects()
			
		elif not ability_state.active and quantum_effect_active:
			quantum_effect_active = false
			clear_quantum_world_effects()

func create_quantum_world_effects():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "QuantumEffectLayer"
	canvas_layer.layer = 5
	add_child(canvas_layer)
	
	var overlay = ColorRect.new()
	overlay.name = "QuantumOverlay"
	overlay.size = Vector2(1280, 720)
	canvas_layer.add_child(overlay)
	
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		
		var x = randf_range(0, 1280)
		var y = randf_range(0, 720)
		
		particle.position = Vector2(x, y)
		canvas_layer.add_child(particle)
		quantum_particles.append(particle)
	
	var time_distortion = ColorRect.new()
	time_distortion.name = "TimeDistortion"
	time_distortion.size = Vector2(1280, 720)
	canvas_layer.add_child(time_distortion)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(time_distortion, "color:a", 0.15, 0.5)
	tween.tween_property(time_distortion, "color:a", 0.0, 0.5)

func update_quantum_world_effects(delta):
	for particle in quantum_particles:
		if is_instance_valid(particle):
			var move_x = randf_range(-1, 1) * 100 * delta
			var move_y = randf_range(-1, 1) * 100 * delta
			
			particle.position += Vector2(move_x, move_y)
			
			if particle.position.x < 0:
				particle.position.x = 1280
			elif particle.position.x > 1280:
				particle.position.x = 0
				
			if particle.position.y < 0:
				particle.position.y = 720
			elif particle.position.y > 720:
				particle.position.y = 0
				
			var size_scale = randf_range(0.8, 1.2)
			particle.size = Vector2(3, 3) * size_scale

func clear_quantum_world_effects():
	var effect_layer = get_node_or_null("QuantumEffectLayer")
	if effect_layer:
		effect_layer.queue_free()
	
	quantum_particles.clear()

func setup_transition_layer():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "TransitionLayer"
	add_child(canvas_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.position = Vector2.ZERO
	canvas_layer.add_child(fade_rect)
	
	get_viewport().size_changed.connect(update_fade_rect_size)

func update_fade_rect_size():
	if fade_rect:
		fade_rect.size = get_viewport().get_visible_rect().size
		fade_rect.position = Vector2.ZERO

func direct_scene_change(next_scene_path: String):
	Global.level_changed = true
	Global.coins_collected = 0
	call_deferred("_deferred_change_scene", next_scene_path)

func _deferred_change_scene(next_scene_path):
	get_tree().change_scene_to_file(next_scene_path)
