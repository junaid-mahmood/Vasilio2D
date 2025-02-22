extends AnimatedSprite2D

var is_dying := false
const DEATH_SCALE = Vector2(2, 2)  
const NORMAL_SCALE = Vector2(1, 1)

func _ready() -> void:
	animation = "idle"
	play()
	scale = NORMAL_SCALE

func handle_death():
	is_dying = true
	animation = "death"
	frame = 0
	scale = DEATH_SCALE  
	play()

func handle_hurt():
	scale = NORMAL_SCALE
	animation = "hurt"
	frame = 0
	play()

func handle_attack():
	scale = NORMAL_SCALE
	animation = "attack"
	frame = 0
	play()

func handle_idle():
	scale = NORMAL_SCALE
	animation = "idle"
	frame = 0
	play()

func handle_run():
	scale = NORMAL_SCALE
	animation = "run"
	frame = 0
	play()
