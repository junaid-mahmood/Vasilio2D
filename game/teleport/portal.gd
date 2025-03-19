extends Area2D

@export var speed: float = 1000
var velocity: Vector2 = Vector2.ZERO
var start_pos = Vector2.ZERO
var set_pos = Vector2.ZERO
var portal_number := 0  # 1 for first portal, 2 for second portal
var lifetime := 15.0    # Portal lifetime in seconds
var lifetime_timer := 0.0

func _ready() -> void:
	start_pos = global_position
	$Sprite2D.animation = "default"
	
	# Add to portals group for tracking
	add_to_group("portals")
	
	# Add a subtle pulsing effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops()  # Make it loop indefinitely
	pulse_tween.tween_property($Sprite2D, "scale", Vector2(1.1, 1.1), 0.5)
	pulse_tween.tween_property($Sprite2D, "scale", Vector2(0.9, 0.9), 0.5)
	
	# Set color based on portal number
	if Global.portal1 == Vector2.ZERO:
		portal_number = 1
		$Sprite2D.modulate = Color(0.2, 0.6, 1.0)  # Blue for portal 1
	else:
		portal_number = 2
		$Sprite2D.modulate = Color(1.0, 0.4, 0.8)  # Pink for portal 2
	
	# Start lifetime timer
	lifetime_timer = lifetime

func _process(delta):
	# Handle portal movement
	if velocity != Vector2.ZERO:
		position += velocity * delta
	
	# Check if portal should be destroyed
	if set_pos != Global.portal1 and set_pos != Global.portal2 and velocity == Vector2.ZERO:
		fade_out_and_destroy()
	
	# Add particle effects if they exist
	if has_node("Particles") and $Particles.emitting == false:
		$Particles.emitting = true
	
	# Handle portal lifetime
	if lifetime_timer > 0:
		lifetime_timer -= delta
		
		# Start fading out when close to expiration
		if lifetime_timer < 3.0:
			var alpha = lifetime_timer / 3.0
			$Sprite2D.modulate.a = alpha
		
		# Destroy when lifetime ends
		if lifetime_timer <= 0:
			fade_out_and_destroy()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "teleport":
		return  # Don't stop when player enters
	
	if velocity != Vector2.ZERO:
		velocity = Vector2.ZERO
		
		var direction = (start_pos - global_position).normalized() 
		global_position += direction * 10
		$Sprite2D.animation = "portal"
		
		# Create impact effect
		create_impact_effect()

func create_impact_effect() -> void:
	# Create a ring effect when portal hits something
	var ring = ColorRect.new()
	ring.color = Color(0.2, 0.6, 1.0, 0.5)
	ring.size = Vector2(10, 10)
	ring.position = Vector2(-5, -5)
	add_child(ring)
	
	var tween = create_tween()
	tween.tween_property(ring, "size", Vector2(60, 60), 0.3)
	tween.parallel().tween_property(ring, "position", Vector2(-30, -30), 0.3)
	tween.parallel().tween_property(ring, "color:a", 0, 0.3)
	tween.tween_callback(ring.queue_free)

func fade_out_and_destroy() -> void:
	# Create a smooth fade out effect before destroying
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0, 0.5)
	tween.tween_callback(queue_free)
	
	# Notify any listeners that this portal is being destroyed
	if portal_number == 1 and Global.portal1 == global_position:
		Global.portal1 = Vector2.ZERO
		if Global.portals == 2:
			Global.portals = 1
		elif Global.portals == 1:
			Global.portals = 0
	elif portal_number == 2 and Global.portal2 == global_position:
		Global.portal2 = Vector2.ZERO
		if Global.portals == 2:
			Global.portals = 1
