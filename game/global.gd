extends Node

var weapon := 'gun'

var player_position := Vector2.ZERO

var dead := false

var has_shield := false

var coins_collected := 0

#if shooting, player_pos, facing_right
var shoot = [false, Vector2.ZERO, false]

#if shooting, enemy_pos, target_pos
var enemy_shoot = [false, Vector2.ZERO, Vector2.ZERO]

#if shooting, plauer_pos
var shoot_portal = [false, Vector2.ZERO]

var player = ''

var portal1 = Vector2.ZERO
var portal2 = Vector2.ZERO
var portals = 0
