extends Control

@onready var label = $Name
@onready var numberOfPotions = $NumberOfPotions

var selectedPotionType = PotionProperties.PotionType.None;

func _enter_tree() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);

func _on_potions_manager_selected_potion_type_changed(potionType: PotionProperties.PotionType) -> void:
	selectedPotionType = potionType;
	evaluateNumber(potionType);
	evaluateText(potionType);

func getNumberOfPotionsByType(potionType: PotionProperties.PotionType) -> String:
	var potions = PlayerPotions.potionsDictionary.get(potionType);
	if potions == null:
		return ""
	else:
		return str(potions.size())

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
