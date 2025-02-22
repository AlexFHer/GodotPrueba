extends Node

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggleLeftPotion"):
		PlayerPotions.toggleLeftPotion();
	
	if Input.is_action_just_pressed("toggleRightPotion"):
		PlayerPotions.toggleRightPotion();
	
	if Input.is_action_just_pressed("usePotion"):
		usePotion()

func usePotion() -> void:
	if PlayerPotions.selectedPotionType == PotionProperties.PotionType.None:
		return;
	
	PlayerPotions.usePotion()
