extends Area2D

var on_ladder:bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ladder_body_entered(body: Node2D) -> void:
	if "player" in body.name:
		on_ladder = true
		if body.has_method("set_on_ladder"):
			body.set_on_ladder(true)



func _on_ladder_body_exited(body: Node2D) -> void:
	if "player" in body.name:
		on_ladder = false
		if body.has_method("set_on_ladder"):
			body.set_on_ladder(false)
