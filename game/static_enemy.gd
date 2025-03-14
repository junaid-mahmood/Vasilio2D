extends Area2D

@onready var ray_cast = $RayCast2D
@export var detection_radius := 500  # Increased detection radius
var player_position
var health := 3  # Takes 3 hits to destroy
var can_shoot := true
var shoot_cooldown := 1.5  # Reduced cooldown time for more frequent shooting

func _ready():
    # Add to enemies group
    add_to_group("enemies")
    
    # Start the shooting timer
    $ShootTimer.wait_time = shoot_cooldown
    $ShootTimer.start()
    
    # Start idle animation
    $AnimationPlayer.play("idle")
    
    # Debug print
    print("Static enemy initialized with detection radius: " + str(detection_radius))
    print("Shoot cooldown set to: " + str(shoot_cooldown))

func _process(delta):
    # Get player position from global
    player_position = Global.player_position
    
    if player_position == Vector2.ZERO:
        return  # Player not initialized yet
    
    # Calculate distance to player
    var distance_to_player = global_position.distance_to(player_position)
    
    # Debug shooting conditions
    if distance_to_player <= detection_radius:
        print("Player in range at distance: " + str(distance_to_player))
        if not can_shoot:
            print("Enemy in range but on cooldown")
        elif Global.dead:
            print("Enemy in range but player is dead")
    
    # Only shoot if player is within detection radius
    if distance_to_player <= detection_radius and can_shoot and not Global.dead:
        print("Enemy attempting to shoot at player. Distance: " + str(distance_to_player))
        
        # Calculate direction to player
        var dir_to_player = global_position.direction_to(player_position)
        
        # Update raycast to check for obstacles
        ray_cast.target_position = dir_to_player * detection_radius
        ray_cast.force_raycast_update()
        
        # Check if raycast hit something
        var collision_object = ray_cast.get_collider()
        
        if collision_object:
            print("Raycast hit: " + collision_object.name)
        
        # If raycast didn't hit anything or hit player (clear line of sight to player)
        # More permissive check - shoot even if there's something in the way sometimes
        if collision_object == null or "player" in collision_object.name.to_lower() or "tarzan" in collision_object.name.to_lower() or randf() < 0.3:
            print("Enemy has clear line of sight to player or taking a chance shot")
            
            # Adjust target position to aim at player's center
            var target_pos = player_position
            target_pos.y -= 12  # Aim slightly higher to hit player center
            
            # Tell global that enemy is shooting
            Global.enemy_shoot = [true, global_position, target_pos]
            print("Enemy shooting at: " + str(target_pos))
            
            # Start cooldown
            can_shoot = false
            $ShootTimer.start()
            
            # Visual feedback for shooting
            $AnimationPlayer.play("shoot")
            await $AnimationPlayer.animation_finished
            $AnimationPlayer.play("idle")

func take_damage():
    health -= 1
    print("Enemy taking damage. Health: " + str(health))
    
    # Visual feedback for taking damage
    var tween = create_tween()
    tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
    tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
    
    # Shoot back immediately when hit
    if can_shoot and not Global.dead and player_position != Vector2.ZERO:
        print("Enemy shooting back after being hit!")
        
        # Tell global that enemy is shooting
        Global.enemy_shoot = [true, global_position, player_position]
        
        # Start cooldown
        can_shoot = false
        $ShootTimer.start()
        
        # Visual feedback for shooting
        $AnimationPlayer.play("shoot")
        await $AnimationPlayer.animation_finished
        $AnimationPlayer.play("idle")
    
    if health <= 0:
        print("Enemy defeated")
        # Play death animation if available, otherwise just free
        queue_free()

# Add enemy_damage method to handle Tarzan's attacks
func enemy_damage(damage_amount):
    print("Enemy taking damage: " + str(damage_amount))
    
    # Actually use the damage amount instead of just reducing by 1
    health -= 1  # Simplify to take 1 damage per hit for consistency
    
    # Create damage number
    var damage_number = preload("res://damage_number.tscn").instantiate()
    damage_number.position = global_position + Vector2(0, -20)
    
    # Set the damage value using the correct method
    if damage_number.has_method("set_damage"):
        damage_number.set_damage(damage_amount)
    
    get_parent().add_child(damage_number)
    
    # Visual feedback for taking damage
    var tween = create_tween()
    tween.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
    tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1.0), 0.1)
    
    # Shoot back immediately when hit
    if can_shoot and not Global.dead and player_position != Vector2.ZERO:
        print("Enemy shooting back after being hit!")
        
        # Tell global that enemy is shooting
        Global.enemy_shoot = [true, global_position, player_position]
        
        # Start cooldown
        can_shoot = false
        $ShootTimer.start()
        
        # Visual feedback for shooting
        $AnimationPlayer.play("shoot")
        await $AnimationPlayer.animation_finished
        $AnimationPlayer.play("idle")
    
    print("Enemy health after damage: " + str(health))
    
    if health <= 0:
        print("Enemy defeated")
        # Play death animation if available, otherwise just free
        queue_free()

func _on_shoot_timer_timeout():
    can_shoot = true
    print("Enemy can shoot again")
    
    # Try to shoot immediately when cooldown ends
    if player_position != Vector2.ZERO:
        var distance_to_player = global_position.distance_to(player_position)
        if distance_to_player <= detection_radius and not Global.dead:
            print("Enemy attempting to shoot after cooldown")
            
            # Tell global that enemy is shooting
            Global.enemy_shoot = [true, global_position, player_position]
            
            # Start cooldown
            can_shoot = false
            $ShootTimer.start()
            
            # Visual feedback for shooting
            $AnimationPlayer.play("shoot")
            await $AnimationPlayer.animation_finished
            $AnimationPlayer.play("idle")

func _on_area_entered(area):
    print("Area entered enemy: " + area.name)
    
    # Check if hit by player's arrow/bullet
    if area.has_method("_this_is_bow"):
        print("Enemy hit by bow")
        take_damage()
    # Check for Tarzan's attacks
    elif "tarzan" in area.name.to_lower():
        print("Enemy hit by Tarzan")
        take_damage() 