extends Area2D

@onready var ray_cast = $RayCast2D
@export var detection_radius := 300
var player_position
var health := 3  # Takes 3 hits to destroy
var can_shoot := true
var shoot_cooldown := 2.0  # Seconds between shots

func _ready():
    # Start the shooting timer
    $ShootTimer.wait_time = shoot_cooldown
    $ShootTimer.start()
    
    # Start idle animation
    $AnimationPlayer.play("idle")

func _process(delta):
    # Get player position from global
    player_position = Global.player_position
    
    if player_position == Vector2.ZERO:
        return  # Player not initialized yet
    
    # Calculate distance to player
    var distance_to_player = global_position.distance_to(player_position)
    
    # Only shoot if player is within detection radius
    if distance_to_player <= detection_radius and can_shoot and not Global.dead:
        # Calculate direction to player
        var dir_to_player = global_position.direction_to(player_position)
        
        # Update raycast to check for obstacles
        ray_cast.target_position = dir_to_player * detection_radius
        ray_cast.force_raycast_update()
        
        # Check if raycast hit something
        var collision_object = ray_cast.get_collider()
        
        # If raycast didn't hit anything (clear line of sight to player)
        if collision_object == null or "player" in collision_object.name.to_lower():
            # Adjust target position to aim at player's center
            var target_pos = player_position
            target_pos.y -= 12  # Aim slightly higher to hit player center
            
            # Tell global that enemy is shooting
            Global.enemy_shoot = [true, global_position, target_pos]
            
            # Start cooldown
            can_shoot = false
            $ShootTimer.start()
            
            # Visual feedback for shooting
            $AnimationPlayer.play("shoot")
            await $AnimationPlayer.animation_finished
            $AnimationPlayer.play("idle")

func take_damage():
    health -= 1
    
    # Visual feedback for taking damage
    var tween = create_tween()
    tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
    tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
    
    if health <= 0:
        # Play death animation if available, otherwise just free
        queue_free()

func _on_shoot_timer_timeout():
    can_shoot = true

func _on_area_entered(area):
    # Check if hit by player's arrow/bullet
    if area.has_method("_this_is_bow"):
        take_damage() 