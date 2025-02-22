extends Control

@onready var label = $Name
@onready var numberOfPotions = $NumberOfPotions

var selectedPotionType = PotionProperties.PotionType.None;

func _enter_tree() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);
	PlayerPotions.selectedPotionChanged.connect(_on_selected_potion_changed);

func getNumberOfPotionsByType(potionType: PotionProperties.PotionType) -> String:
	var potionSize = PlayerPotions.potionsDictionary.get(potionType);
	if potionSize == 0:
		return ""
	else:
		return str(potionSize)

func evaluateText(potionType: PotionProperties.PotionType) -> void:
	match(potionType):
		PotionProperties.PotionType.Jump:
			label.text = "Jump"
		PotionProperties.PotionType.Speed:
			label.text = "Speed"
		PotionProperties.PotionType.Fire:
			label.text = "Fire"
		_:
			label.text = "No potions left"

func evaluateNumber(potionType: PotionProperties.PotionType) -> void:
	numberOfPotions.text = getNumberOfPotionsByType(potionType)


func _on_potions_change(potions: Dictionary):
	evaluateNumber(selectedPotionType)

func _on_selected_potion_changed(potionType: PotionProperties.PotionType) -> void:
	selectedPotionType = potionType;
	evaluateNumber(potionType);
	evaluateText(potionType);
