extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var flicker_timer: Timer = $FlickerTimer

var base_energy: float = 1.2
var flicker_range: float = 0.2
var on := true

func _ready() -> void:
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)
	animation_player.play("default")
	add_to_group("torches")


func toggle_torch():
	animation_player.pause()
	on = false
	$PointLight2D.enabled = false
	$burning.visible = false
	$burnt.visible = true
	


func _on_flicker_timer_timeout() -> void:
	if on:
		var random_energy = randf_range(-flicker_range, flicker_range)
		point_light_2d.energy = base_energy + random_energy
