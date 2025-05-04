extends Node

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggleLeftPotion"):
		print("toggleLeftPotion")
		PlayerPotions.toggleLeftPotion();
	
	if Input.is_action_just_pressed("toggleRightPotion"):
		print("toggleRightPotion")
		PlayerPotions.toggleRightPotion();
	
	if Input.is_action_just_pressed("usePotion"):
		usePotion()

func usePotion() -> void:
	if PlayerPotions.selectedPotionType == PotionTypes.PotionType.None:
		return;
	
	var selectedPotionToMerge = PotionMergerService.selectedPotionToMerge;
	if selectedPotionToMerge != PotionTypes.PotionType.None:
		mergePotion();
	else:
		PlayerPotions.usePotion()

func mergePotion() -> void:
	var selectedPotionToMerge = PotionMergerService.selectedPotionToMerge;
	if selectedPotionToMerge == PlayerPotions.selectedPotionType:
		PlayerPotions.usePotion()
	else:
		pass
