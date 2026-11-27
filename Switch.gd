extends Interactable

var is_activated: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prompt_message = "Pull Arena Lever"

func _on_interact(interactor: Node3D) -> void:
	is_activated = not is_activated
	print(interactor.name,  " toggled the lever! Active: ", is_activated)
	#if interactor is PlayerCharacter:
		#interactor.take_damage(10)
		#print("Took damage!")
