extends Node

const PotionEnum = preload("res://assets/potions/shared/models/potion-types.gd").PotionType

var selectedPotion: Potion;

signal jumpPotionUsed;
signal SpeedPotionUsed;
signal firePotionUsed;

signal selectedPotionTypeChanged(potionType: PotionEnum);
signal selectedPotionChanged(potion: Potion)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("usePotion"):
		usePotion()

func usePotion() -> void:
	if not PlayerPotions.isThereAnyPotionOfType(selectedPotion.type):
		return;
		
	match selectedPotion.type:
		PotionEnum.Jump:
			useJumpPotion();
		PotionEnum.Speed:
			useSpeedPotion();
		PotionEnum.Fire:
			useFirePotion();
	
	PlayerPotions.removeOnePotionByType(selectedPotion.type)

func useJumpPotion() -> void:
	jumpPotionUsed.emit()

func useSpeedPotion() -> void:
	SpeedPotionUsed.emit()

func useFirePotion() -> void:
	firePotionUsed.emit()
