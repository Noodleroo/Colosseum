class_name ArenaHUD
extends CanvasLayer

@onready var round_bar: ProgressBar = $HUDRoot/RoundProgress/ProgressBar
@onready var round_label: Label = $HUDRoot/RoundProgress/RoundLabel

@onready var class_label: Label = $HUDRoot/StatBadge/VBoxContainer/ClassLabel
@onready var kills_label: Label = $HUDRoot/StatBadge/VBoxContainer/KillsLabel

@onready var ability_bar: ProgressBar = $HUDRoot/Health/Ability/ProgressBar
@onready var health_bar: ProgressBar = $HUDRoot/Health/HealthBar/HealthBar

func update_health(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current

func update_ability_charge(current: float, max_charge: float) -> void:
	ability_bar.max_value = max_charge
	ability_bar.value = current

func update_round(round_number: int, progress: float) -> void:
	round_label.text = "Round: %d" % round_number
	round_bar.value = progress

func update_kills(kills: int) -> void:
	kills_label.text = "Kills: %d" % kills

func set_player_class(class_name_text: String) -> void:
	class_label.text = "Class: %s" % class_name_text
