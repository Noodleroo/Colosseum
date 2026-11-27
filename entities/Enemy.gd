class_name Enemy
extends CharacterBody3D

signal health_changed(current: float, max_hp: float)
signal died(enemy: Enemy)

@export var stats: EnemyData

var current_health: float
var target: Node3D = null
var attack_timer: float = 0.0
var gravity: float = ProjectSettings.get("physics/3d/default_gravity")

func _ready() -> void:
	# Fallback values prevent crashes if you forget to assign a .tres file
	current_health = stats.max_health if stats else 50.0
	target = get_tree().get_first_node_in_group("player") as Node3D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if attack_timer > 0.0:
		attack_timer -= delta

	if target and is_instance_valid(target):
		_handle_combat_movement(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 5.0)
		velocity.z = move_toward(velocity.z, 0.0, 5.0)

	move_and_slide()


func _handle_combat_movement(delta: float) -> void:
	var speed := stats.move_speed if stats else 3.5
	var range_limit := stats.attack_range if stats else 1.2

	# Keep movement flat on the arena floor
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if distance > 0.01:
		var direction := to_target.normalized()
		var target_angle := atan2(direction.x, direction.z) + PI
		rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)

		# --- PASTE YOUR HIGHLIGHTED CODE HERE ---
		var stop_distance := 1.05 # Right where the two 0.5m capsules touch

		if distance > stop_distance:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0

		if distance <= range_limit and attack_timer <= 0.0:
			_perform_attack()

# Virtual method: Bosses can override this to do slam attacks or projectiles
func _perform_attack() -> void:
	attack_timer = stats.attack_cooldown if stats else 1.5
	var dmg := stats.damage if stats else 10.0

	# Brief 0.35s wind-up so the player has time to dodge or strike first
	await get_tree().create_timer(0.35).timeout

	# Check that both the enemy and player are still alive and in range
	if not is_instance_valid(self) or not is_instance_valid(target):
		return

	var range_limit := stats.attack_range if stats else 1.2
	if global_position.distance_to(target.global_position) <= range_limit + 0.3:
		if target.has_method(&"take_damage"):
			target.take_damage(dmg)

func take_damage(amount: float) -> void:
	var max_hp := stats.max_health if stats else 50.0
	current_health = clamp(current_health - amount, 0.0, max_hp)
	health_changed.emit(current_health, max_hp)

	if current_health <= 0.0:
		die()


func die() -> void:
	died.emit(self)
	queue_free()
