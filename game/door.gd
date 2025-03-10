extends Area2D

var triggered = false

func _ready():
	print("Door script initialized!")

func _process(_delta):
	if triggered:
		return
		
	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			if not triggered:
				triggered = true
				print("Player touched door!")
				print("Player has touched the door!")
