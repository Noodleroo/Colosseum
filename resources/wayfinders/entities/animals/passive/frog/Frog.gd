## Frog entity that hops periodically or leaps away when a player enters its detection zone.
class_name Frog
extends Entity

@export_group("Frog Physics & Behavior")
## Vertical jump force when the frog hops
@export var jump_force: float = 5.0

## Minimum and maximum time (in seconds) between idle hops
@export var min_hop_interval: float = 2.0
@export var max_hop_interval: float = 4.0

var hop_interval = min_hop_interval + max_hop_interval
var hop_timer: float = 0.0

# Target rotation direction for smooth turning
var target_facing_direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	super._ready()
	_reset_hop_timer()

## Called when the frog takes damage from a player attack or hazard
func take_damage(amount: float) -> void:
	super.take_damage(amount)
	print("Frog took %.1f damage! Remaining HP: %.1f" % [amount, current_health])
	if current_health > 0.0:
		flee_from(global_position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)))

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	# Smoothly turn the model toward target facing direction
	_update_model_rotation(delta)
	
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		
		hop_timer -= delta
		if hop_timer <= 0.0:
			hop_randomly()
			_reset_hop_timer()

	move_and_slide()

## Smoothly rotates the model_node towards target_facing_direction
func _update_model_rotation(delta: float) -> void:
	if model_node == null or target_facing_direction == Vector3.ZERO:
		return

	# Calculate desired target basis (rotation)
	var target_basis := Basis.looking_at(target_facing_direction, Vector3.UP)
	
	# Smoothly interpolate current basis toward target basis
	model_node.basis = model_node.basis.slerp(target_basis, 12.0 * delta)

## Performs an idle hop in a random direction
func hop_randomly() -> void:
	var random_angle := randf_range(0.0, TAU)
	var dir := Vector3(cos(random_angle), 0.0, sin(random_angle)).normalized()
	_perform_hop(dir)

func _perform_hop(direction: Vector3) -> void:
	if direction == Vector3.ZERO:
		return

	var jump_dir := direction.normalized()

	# 1. Edge safety check
	if not _is_hop_safe(jump_dir):
		return

	# 2. Apply jump velocity
	var speed := data.move_speed if data else move_speed
	velocity.x = jump_dir.x * speed
	velocity.z = jump_dir.z * speed
	velocity.y = jump_force

	# 3. Update target facing direction so _update_model_rotation() turns smoothly
	target_facing_direction = Vector3(jump_dir.x, 0.0, jump_dir.z)

	play_animation(&"jump")

## Raycasts ahead at the target landing spot in world space
func _is_hop_safe(jump_dir: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	
	# Calculate landing check point 1.2 units ahead along jump_dir
	var check_distance := 1.2
	var landing_spot := global_position + (jump_dir.normalized() * check_distance)
	
	# Raycast straight down at that location
	var ray_start := landing_spot + Vector3(0, 0.5, 0)
	var ray_end := landing_spot + Vector3(0, -2.5, 0)
	
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [get_rid()] # Exclude self
	
	var result := space_state.intersect_ray(query)
	return not result.is_empty() # Safe if floor is detected

## Flees directly away from a target position (e.g., Player)
func flee_from(target_position: Vector3) -> void:
	var flee_dir := (global_position - target_position).normalized()
	flee_dir.y = 0.0
	
	# If fleeing straight back is unsafe, try turning left or right
	if not _is_hop_safe(flee_dir):
		var left_dir := flee_dir.cross(Vector3.UP)
		var right_dir := -left_dir
		
		if _is_hop_safe(left_dir):
			flee_dir = left_dir
		elif _is_hop_safe(right_dir):
			flee_dir = right_dir

	_perform_hop(flee_dir)
	_reset_hop_timer()

func _reset_hop_timer() -> void:
	hop_timer = randf_range(min_hop_interval, max_hop_interval)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		flee_from(body.global_position)
