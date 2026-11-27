class_name PlayerCharacter
extends CharacterBody3D

@onready var coyote_check: RayCast3D = $CoyoteCheck
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var interaction_ray: RayCast3D = $CameraRig/SpringArm3D/Camera3D/InteractionRay

@onready var melee_hitbox: Area3D = $MeleeHitbox

@export var arena_hud: PackedScene
var hud: ArenaHUD

@export var fist_damage: float = 15.0
@export var attack_cooldown: float = 0.4
var can_attack: bool = true
var is_attacking: bool = false

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 7.0
const STAND_HEIGHT: float = 2.0
const CROUCH_HEIGHT: float = 1.0
const STARTING_HEALTH: int = 100

var max_health: int = STARTING_HEALTH
var cur_health: int = max_health

var crouch_speed: float = SPEED * 0.5
var current_speed: float = SPEED
var is_crouching: bool = false

var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_DURATION: float = 0.15
var coyote_timer: float = 0.0
const COYOTE_DURATION: float = 0.15

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	if arena_hud:
		print("Hud Present! Updating Values")
		hud = arena_hud.instantiate() as ArenaHUD
		add_child(hud)
		hud.add_to_group("hud")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"primary_action") and can_attack:
		_perform_fist_attack()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_on_floor():
		coyote_timer = COYOTE_DURATION
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("movement_jump"):
		jump_buffer_timer = JUMP_BUFFER_DURATION
	else:
		jump_buffer_timer -= delta

	var can_coyote_jump := coyote_timer > 0.0 and coyote_check.is_colliding()
	var has_buffered_jump := jump_buffer_timer > 0.0

	if has_buffered_jump and (is_on_floor() or can_coyote_jump):
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		if is_crouching and can_uncrouch():
			toggle_crouch()
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("movement_crouch"):
		toggle_crouch()

	var input_dir := Input.get_vector("movement_left", "movement_right", "movement_up", "movement_down")
	var direction := Vector3.ZERO

	if input_dir != Vector2.ZERO:
		var active_cam := get_viewport().get_camera_3d()
		var cam_basis: Basis = active_cam.global_transform.basis if active_cam else global_transform.basis

		var cam_forward: Vector3 = cam_basis.z
		var cam_right: Vector3 = cam_basis.x
		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		direction = (cam_right * input_dir.x) + (cam_forward * input_dir.y)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if not is_attacking:
			var target_angle := atan2(direction.x, direction.z) + PI
			rotation.y = lerp_angle(rotation.y, target_angle, 6.0 * delta)
		
		var target_angle := atan2(direction.x, direction.z) + PI
		rotation.y = lerp_angle(rotation.y, target_angle, 6.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func toggle_crouch() -> void:
	if is_crouching and not can_uncrouch():
		return

	is_crouching = not is_crouching

	if is_crouching:
		current_speed = crouch_speed
		collision_shape.shape.height = CROUCH_HEIGHT
		mesh_instance.mesh.height = CROUCH_HEIGHT
	else:
		current_speed = SPEED
		collision_shape.shape.height = STAND_HEIGHT
		mesh_instance.mesh.height = STAND_HEIGHT

	collision_shape.position.y = 0.0
	mesh_instance.position.y = 0.0

func can_uncrouch() -> bool:
	return not ceiling_check.is_colliding()

func _perform_fist_attack() -> void:
	can_attack = false
	is_attacking = true

	# 1. Find the horizontal direction the camera is facing
	var active_cam := get_viewport().get_camera_3d()
	if active_cam:
		var look_dir := -active_cam.global_transform.basis.z
		look_dir.y = 0.0

		if look_dir.length_squared() > 0.001:
			look_dir = look_dir.normalized()
			var target_angle := atan2(look_dir.x, look_dir.z) + PI

			# Calculate the shortest turn so the character never spins 360 degrees
			var shortest_turn := angle_difference(rotation.y, target_angle)
			var tween := create_tween()
			tween.tween_property(self, "rotation:y", rotation.y + shortest_turn, 0.2)
			await tween.finished

	# 2. Check the hitbox now that the character and MeleeHitbox face the target
	for body in melee_hitbox.get_overlapping_bodies():
		if body != self and body.has_method(&"take_damage"):
			body.take_damage(fist_damage)
			print("Hit %s for %.1f damage!" % [body.name, fist_damage])

	is_attacking = false

	# 3. Wait for the cooldown before allowing the next swing
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int):
	cur_health -= amount

	if arena_hud:
		hud.update_health(cur_health, max_health)
		
	print(cur_health)
