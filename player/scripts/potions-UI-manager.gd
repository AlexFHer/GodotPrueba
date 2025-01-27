extends Control

const PotionEnum = preload("res://assets/potions/shared/models/potion-types.gd").PotionType

@onready var label = $Name
@onready var numberOfPotions = $NumberOfPotions

var selectedPotionType = PotionEnum.None;

func _enter_tree() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);

func _on_potions_manager_selected_potion_type_changed(potionType: PotionEnum) -> void:
	selectedPotionType = potionType;
	evaluateNumber(potionType);
	evaluateText(potionType);

func getNumberOfPotionsByType(potionType: PotionEnum) -> String:
	var potions = PlayerPotions.potionsDictionary.get(potionType);
	if potions == null:
		return ""
	else:
		return str(potions.size())

func evaluateText(potionType: PotionEnum) -> void:
	match(potionType):
		PotionEnum.Jump:
			label.text = "Jump"
		PotionEnum.Speed:
			label.text = "Speed"
		PotionEnum.Fire:
			label.text = "Fire"
		_:
			label.text = "No potions left"

func evaluateNumber(potionType: PotionEnum) -> void:
	numberOfPotions.text = getNumberOfPotionsByType(potionType)


func _on_potions_change(potions: Dictionary): 
	evaluateNumber(selectedPotionType)
