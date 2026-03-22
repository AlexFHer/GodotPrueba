extends Control

@onready var leftPotionCountLabel: Label = %LeftPotionCount
@onready var rightPotionCountLabel: Label = %RightPotionCount
@onready var leftPotionIconTexture: TextureRect = %LeftPotionIcon
@onready var rightPotionIconTexture: TextureRect = %RightPotionIcon

var firePotionIcon: Texture = preload("res://assets/potions/fire-potion/Fire_Poti_icon.png")
var jumpPotionIcon: Texture = preload("res://assets/potions/jump-potion/Jump_Poti_icon.png")
var speedPotionIcon: Texture = preload("res://assets/potions/speed-potion/Speed_Poti_icon.png")
var fireAndSpeedPotionIcon: Texture = preload("res://assets/potions/merged_potions/speed_and_fire/Fire_Poti_icon.png");

var selectedLeftPotionType := PotionTypes.PotionType.None;
var selectedRightPotionType := PotionTypes.PotionType.None;

func _enter_tree() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);
	PlayerPotions.selectedLeftPotionChanged.connect(_on_selected_left_potion_changed);
	PlayerPotions.selectedRightPotionChanged.connect(_on_selected_right_potion_changed);
				
# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("combineSelection"):
# 		_on_combine_selection_pressed()

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
		PotionTypes.PotionType.SpeedAndFire:
			return fireAndSpeedPotionIcon
		_:
			return null

func evaluateLeftIcon(potionType: PotionTypes.PotionType) -> void:
	leftPotionIconTexture.texture = _getPotionIcon(potionType)

func evaluateRightIcon(potionType: PotionTypes.PotionType) -> void:
	rightPotionIconTexture.texture = _getPotionIcon(potionType)

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
