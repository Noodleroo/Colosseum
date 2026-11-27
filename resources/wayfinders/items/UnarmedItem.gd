class_name UnarmedItem
extends Item

@export var damage: float = 10.0

func use_primary(user: Node3D, _target_info: Dictionary) -> bool:
	if user.has_node("RayCast3D"):
		var raycast: RayCast3D = user.get_node("RayCast3D")
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider.has_method(&"take_damage"):
				collider.take_damage(damage, user)
				return true
	return false
