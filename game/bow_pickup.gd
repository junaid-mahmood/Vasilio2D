extends Area2D

func _process(delta):
    # Make the bow float up and down for visual effect
    position.y += sin(Time.get_ticks_msec() / 200) * delta * 80

func _on_body_entered(body: Node2D) -> void:
    # Check if the body is the player
    if "has_bow" in body:
        body.has_bow = true
        Global.weapon = "bow"  # Switch to bow automatically
        queue_free() 