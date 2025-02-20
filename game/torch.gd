extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var flicker_timer: Timer = $FlickerTimer

var base_energy: float = 1.2
var flicker_range: float = 0.2

func _ready() -> void:
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)
	animation_player.play("default")

func _on_flicker_timer_timeout() -> void:
	var random_energy = randf_range(-flicker_range, flicker_range)
	point_light_2d.energy = base_energy + random_energy
