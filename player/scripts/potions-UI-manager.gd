extends Control

@onready var leftPotionIconTexture: TextureRect = %LeftPotionIcon
@onready var rightPotionIconTexture: TextureRect = %RightPotionIcon

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

func evaluateRightIcon(potionType: PotionTypes.PotionType) -> void:
	rightPotionIconTexture.texture = _getPotionIcon(potionType)

func _on_potions_change(_potions: Dictionary):
	evaluateLeftIcon(selectedLeftPotionType)
	evaluateRightIcon(selectedRightPotionType)

func _on_selected_left_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedLeftPotionType = potionType;
	evaluateLeftIcon(potionType);

func _on_selected_right_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedRightPotionType = potionType;
	evaluateRightIcon(potionType);
