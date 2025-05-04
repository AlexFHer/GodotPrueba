extends PotionBase

func _on_pick_up() -> void:
	PlayerPotions.addPotion(potionType);
	queue_free()


func _on_body_entered(body:Node3D) -> void:
	_on_pick_up()
