class_name ArenaBoss
extends Enemy

var is_enraged: bool = false


func take_damage(amount: float) -> void:
	super.take_damage(amount) # Runs the normal health & death logic first

	# Enter Phase 2 at 50% health
	if not is_enraged and current_health <= (stats.max_health * 0.5):
		is_enraged = true
		stats.move_speed *= 1.4
		print(stats.display_name, " is enraged!")


func _perform_attack() -> void:
	if is_enraged:
		# Example: Boss swings twice as fast in Phase 2
		super._perform_attack()
		attack_timer *= 0.5
	else:
		super._perform_attack()
