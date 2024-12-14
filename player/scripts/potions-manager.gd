extends Node

const PotionEnum = preload("res://assets/potions/resources/potion-types.gd").PotionType

var selectedPotionType: PotionEnum = PotionEnum.Jump;

signal jumpPotionUsed;
signal SpeedPotionUsed;
signal firePotionUsed;

signal selectedPotionTypeChanged(potionType: PotionEnum);

func _ready() -> void:
	selectedPotionTypeChanged.emit(selectedPotionType);

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("usePotion"):
		usePotion()

func usePotion() -> void:
	if not PlayerPotions.isThereAnyPotionOfType(selectedPotionType):
		return;
		
	match selectedPotionType:
		PotionEnum.Jump:
			useJumpPotion();
		PotionEnum.Speed:
			useSpeedPotion();
		PotionEnum.Fire:
			useFirePotion();
	
	PlayerPotions.removeOnePotionByType(selectedPotionType)

func useJumpPotion() -> void:
	jumpPotionUsed.emit()

func useSpeedPotion() -> void:
	SpeedPotionUsed.emit()

func useFirePotion() -> void:
	firePotionUsed.emit()
