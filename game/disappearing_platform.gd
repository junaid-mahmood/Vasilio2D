extends StaticBody2D

@export var visible_time := 2.0
@export var invisible_time := 2.0
@export var initial_delay := 0.0

var timer: float
var is_visible := true

func _ready():
	$Sprite2D.texture = load("res://platform.png")
	$Sprite2D.scale = Vector2(0.5, 0.5)  # Adjust scale as needed
	
	timer = initial_delay if initial_delay > 0 else visible_time
	
	# If starting with a delay, make invisible initially
	if initial_delay > 0:
		is_visible = false
		modulate.a = 0
		$CollisionShape2D.disabled = true

func _process(delta):
	timer -= delta
	
	if timer <= 0:
		is_visible = !is_visible
		
		if is_visible:
			# Make visible
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 1.0, 0.3)
			$CollisionShape2D.disabled = false
			timer = visible_time
		else:
			# Make invisible
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.3)
			$CollisionShape2D.disabled = true
			timer = invisible_time 
