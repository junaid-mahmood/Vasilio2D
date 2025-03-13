extends Node2D

var damage_value = 0
var velocity = Vector2(0, -50)  # Initial upward movement
var lifetime = 0.8  # How long the number stays visible
var time_passed = 0
var color = Color(1, 0.3, 0.3)  # Default red color for damage

func _ready():
	# Randomize the horizontal movement slightly
	velocity.x = randf_range(-20, 20)
	
	# Set up the label
	var label = Label.new()
	label.text = str(damage_value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Make the text small
	var font_size = 12
	label.add_theme_font_size_override("font_size", font_size)
	
	# Set the color
	label.add_theme_color_override("font_color", color)
	
	# Add a slight shadow for better visibility
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	add_child(label)
	
	# Start with a slight scale animation
	scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta):
	# Move the number upward and slow down over time
	position += velocity * delta
	velocity.y += 60 * delta  # Add gravity effect
	
	# Track lifetime
	time_passed += delta
	
	# Fade out near the end of lifetime
	if time_passed > lifetime * 0.5:
		modulate.a = 1.0 - (time_passed - lifetime * 0.5) / (lifetime * 0.5)
	
	# Remove when lifetime is over
	if time_passed >= lifetime:
		queue_free()

func set_damage(value, is_critical = false):
	damage_value = value
	
	# If it's a critical hit, make it bigger and yellow
	if is_critical:
		color = Color(1, 0.9, 0)  # Yellow/gold for critical hits
		scale = Vector2(1.5, 1.5)  # Bigger text
		lifetime = 1.2  # Stay longer 