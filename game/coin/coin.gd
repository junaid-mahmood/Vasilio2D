extends Area2D

var collected = false
var value = 1  # Default coin value
var coin_id = ""  # Unique identifier for this coin

func _ready():
	# Generate a unique ID for this coin based on its position
	coin_id = str(global_position.x) + "_" + str(global_position.y)
	
	# Check if this coin was already collected in this level
	if Global.is_coin_collected(coin_id):
		# This coin was already collected, remove it
		queue_free()
		
	# Start the coin animation if it has one
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play()

func _on_body_entered(body):
	if not collected and body.is_in_group("player"):
		collected = true
		
		# Update coin counters via Global function with ID tracking
		Global.add_coin(value, coin_id)
		
		# Play collection sound if available
		if has_node("CoinSound"):
			$CoinSound.play()
		
		# Play collection animation
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.tween_property(self, "scale", Vector2(0, 0), 0.15)
		
		# Give the sound time to play before removing
		await tween.finished
		
		# Remove the coin
		queue_free()
	
