extends PotionBase

func _on_pick_up() -> void:
	PlayerPotions.addPotion(potionType);
	queue_free()
