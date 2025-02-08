extends Node2D
const bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
const enemy_bullet_scene: PackedScene = preload("res://scenes/enemy_bullet.tscn")




func _on_player_shoot(pos, facing_right):
	var bullet = bullet_scene.instantiate()
	var direction = 1 if facing_right else -1
	bullet.direction = direction
	$Bullets.add_child(bullet)
	pos.y -= 5
	bullet.position = pos + Vector2(6 * direction, 0)


func _on_drone_or_smth_enemy_shoot(pos: Vector2, player_pos: Vector2):
	var bullet = enemy_bullet_scene.instantiate()
	bullet.position = pos
	var direction: Vector2 = (player_pos - pos).normalized()
	bullet.velocity = direction * bullet.speed
	bullet.rotation = direction.angle()
	$EnemyBullets.add_child(bullet)
