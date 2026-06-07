extends Node

var current_active_potion: PotionTypes.PotionType = PotionTypes.PotionType.None
signal activePotionChanged(potionType: PotionTypes.PotionType)

func _ready() -> void:
	PlayerPotions.potionUsed.connect(_on_potion_used)
	PlayerPotions.potionEffectFinished.connect(_on_potion_effect_finished)

func has_active_potion() -> bool:
	return current_active_potion != PotionTypes.PotionType.None

func set_active_potion(potion_type: PotionTypes.PotionType) -> void:
	current_active_potion = potion_type
	activePotionChanged.emit(current_active_potion)

func clear_active_potion() -> void:
	set_active_potion(PotionTypes.PotionType.None)

func _on_potion_used(potion_type: PotionTypes.PotionType) -> void:
	set_active_potion(potion_type)

func _on_potion_effect_finished(potion_type: PotionTypes.PotionType) -> void:
	if current_active_potion == potion_type:
		clear_active_potion()
