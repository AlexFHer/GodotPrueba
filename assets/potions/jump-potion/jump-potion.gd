extends PotionBase

func _on_pick_up() -> void:
	PlayerPotions.addPotion(potion);
	queue_free()
