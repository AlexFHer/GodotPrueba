extends Control

@onready var leftPotionCountLabel: Label = %LeftPotionCount
@onready var rightPotionCountLabel: Label = %RightPotionCount
@onready var leftPotionIconTexture: TextureRect = %LeftPotionIcon
@onready var rightPotionIconTexture: TextureRect = %RightPotionIcon
@onready var leftPotionName: Label = %LeftPotionName
@onready var rightPotionName: Label = %RightPotionName

var firePotionIcon: Texture = preload("res://assets/potions/fire_potion/Fire_Poti_icon.png")
var jumpPotionIcon: Texture = preload("res://assets/potions/jump_potion/Jump_Poti_icon.png")
var speedPotionIcon: Texture = preload("res://assets/potions/speed_potion/Speed_Poti_icon.png")

var selectedLeftPotionType := PotionTypes.PotionType.None;
var selectedRightPotionType := PotionTypes.PotionType.None;

func _ready() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);
	PlayerPotions.selectedLeftPotionChanged.connect(_on_selected_left_potion_changed);
	PlayerPotions.selectedRightPotionChanged.connect(_on_selected_right_potion_changed);
	_on_selected_left_potion_changed(PlayerPotions.selectedLeftPotionType)
	_on_selected_right_potion_changed(PlayerPotions.selectedRightPotionType)
				

func getNumberOfPotionsByType(potionType: PotionTypes.PotionType) -> String:
	var potionSize = PlayerPotions.potionsDictionary.get(potionType);
	if potionSize == 0 or potionSize == null:
		return ""
	else:
		return str(potionSize)

func _getPotionIcon(potionType: PotionTypes.PotionType) -> Texture:
	match(potionType):
		PotionTypes.PotionType.Jump:
			return jumpPotionIcon
		PotionTypes.PotionType.Speed:
			return speedPotionIcon
		PotionTypes.PotionType.Fire:
			return firePotionIcon
		_:
			return null

func evaluateLeftIcon(potionType: PotionTypes.PotionType) -> void:
	leftPotionIconTexture.texture = _getPotionIcon(potionType)
	leftPotionName.text = _get_potion_name(potionType)

func evaluateRightIcon(potionType: PotionTypes.PotionType) -> void:
	rightPotionIconTexture.texture = _getPotionIcon(potionType)
	rightPotionName.text = _get_potion_name(potionType)

func _get_potion_name(potionType: PotionTypes.PotionType) -> String:
	match potionType:
		PotionTypes.PotionType.Jump:
			return "jump_potion_ui_text"
		PotionTypes.PotionType.Speed:
			return "speed_potion_ui_text"
		PotionTypes.PotionType.Fire:
			return "fire_potion_ui_text"
		_:
			return "—"

func evaluateLeftNumber(potionType: PotionTypes.PotionType) -> void:
	leftPotionCountLabel.text = getNumberOfPotionsByType(potionType)

func evaluateRightNumber(potionType: PotionTypes.PotionType) -> void:
	rightPotionCountLabel.text = getNumberOfPotionsByType(potionType)

func _on_potions_change(_potions: Dictionary):
	evaluateLeftNumber(selectedLeftPotionType)
	evaluateRightNumber(selectedRightPotionType)
	evaluateLeftIcon(selectedLeftPotionType)
	evaluateRightIcon(selectedRightPotionType)

func _on_selected_left_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedLeftPotionType = potionType;
	evaluateLeftNumber(potionType);
	evaluateLeftIcon(potionType);

func _on_selected_right_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedRightPotionType = potionType;
	evaluateRightNumber(potionType);
	evaluateRightIcon(potionType);
