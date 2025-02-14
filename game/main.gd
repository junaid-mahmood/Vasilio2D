extends Node

const bullet_scene: PackedScene = preload("res://character/bullet.tscn")
const enemy_bullet_scene: PackedScene = preload("res://enemy/enemy_bullet.tscn")
const bullet_bow_scene: PackedScene = preload("res://bow/bow_bullet.tscn")



func _on_player_shoot(pos, facing_right):
	var bullet = bullet_scene.instantiate()
	var direction = 1 if facing_right else -1
	bullet.direction = direction
	$Bullets.add_child(bullet)
	pos.y -= 20
	bullet.position = pos + Vector2(6 * direction, 0)





func _on_enemy_enemy_shoot(pos: Variant, player_pos: Variant) -> void:
	var bullet = enemy_bullet_scene.instantiate()
	pos.y -= 20
	bullet.position = pos
	var direction: Vector2 = (player_pos - pos).normalized()
	bullet.velocity = direction * bullet.speed
	bullet.rotation = direction.angle()
	$EnemyBullets.add_child(bullet)



func _on_character_body_2d_shoot_bow(pos: Variant, facing_right: Variant) -> void:
	var bullet = bullet_bow_scene.instantiate()
	var direction = 1 if facing_right else -1
	bullet.direction = direction
	$BowBullets.add_child(bullet)
	pos.y -= 20
	bullet.position = pos + Vector2(6 * direction, 0)
