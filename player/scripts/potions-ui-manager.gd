extends Control

@export var display_duration := 3.0
@export var entrance_duration := 0.45

@onready var content: Control = $Content
@onready var leftPotionIconTexture: TextureRect = %LeftPotionIcon
@onready var rightPotionIconTexture: TextureRect = %RightPotionIcon
@onready var leftPotionCountLabel: Label = %LeftPotionCount
@onready var rightPotionCountLabel: Label = %RightPotionCount

var firePotionIcon: Texture = preload("res://assets/potions/fire_potion/Fire_Poti_icon.png")
var jumpPotionIcon: Texture = preload("res://assets/potions/jump_potion/Jump_Poti_icon.png")
var speedPotionIcon: Texture = preload("res://assets/potions/speed_potion/Speed_Poti_icon.png")

var selectedLeftPotionType := PotionTypes.PotionType.None;
var selectedRightPotionType := PotionTypes.PotionType.None;
var _animation: Tween

func _ready() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);
	PlayerPotions.selectedLeftPotionChanged.connect(_on_selected_left_potion_changed);
	PlayerPotions.selectedRightPotionChanged.connect(_on_selected_right_potion_changed);
	_on_selected_left_potion_changed(PlayerPotions.selectedLeftPotionType)
	_on_selected_right_potion_changed(PlayerPotions.selectedRightPotionType)
	_update_inventory_counts()
	hide_immediately()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle-hud"):
		show_potions()

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

func getNumberOfPotionsByType(potionType: PotionTypes.PotionType) -> int:
	return PlayerPotions.potionsDictionary.get(potionType, 0)

func _get_selected_count_text(potionType: PotionTypes.PotionType) -> String:
	if potionType == PotionTypes.PotionType.None:
		return ""
	return str(getNumberOfPotionsByType(potionType))

func evaluateLeftIcon(potionType: PotionTypes.PotionType) -> void:
	leftPotionIconTexture.texture = _getPotionIcon(potionType)
	leftPotionCountLabel.text = _get_selected_count_text(potionType)

func evaluateRightIcon(potionType: PotionTypes.PotionType) -> void:
	rightPotionIconTexture.texture = _getPotionIcon(potionType)
	rightPotionCountLabel.text = _get_selected_count_text(potionType)

func show_potions() -> void:
	if _animation != null:
		_animation.kill()
	if not visible:
		content.position.y = 60.0
		content.modulate.a = 0.0
	show()
	_update_inventory_counts()
	_animation = create_tween()
	_animation.tween_property(content, "position:y", 0.0, entrance_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_animation.parallel().tween_property(content, "modulate:a", 1.0, entrance_duration * 0.6)
	_animation.tween_interval(display_duration)
	_animation.tween_property(content, "position:y", 60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.parallel().tween_property(content, "modulate:a", 0.0, 0.22)
	_animation.tween_callback(hide)

func hide_immediately() -> void:
	if _animation != null:
		_animation.kill()
	content.position.y = 60.0
	content.modulate.a = 0.0
	hide()

func _update_inventory_counts() -> void:
	leftPotionCountLabel.text = _get_selected_count_text(selectedLeftPotionType)
	rightPotionCountLabel.text = _get_selected_count_text(selectedRightPotionType)

func _on_potions_change(_potions: Dictionary):
	_update_inventory_counts()
	evaluateLeftIcon(selectedLeftPotionType)
	evaluateRightIcon(selectedRightPotionType)

func _on_selected_left_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedLeftPotionType = potionType;
	evaluateLeftIcon(potionType);

func _on_selected_right_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedRightPotionType = potionType;
	evaluateRightIcon(potionType);
