extends Control

@onready var numberOfPotions: Label = $NumberOfPotions
@onready var potionsTimer: Timer = %PotionsTimer
@onready var potionsTimerLabel: Label = %PotionTimerLabel
@onready var potionIconTexture: TextureRect = $CurrentPotionTexture

var firePotionIcon: Texture = preload("res://assets/potions/fire-potion/Fire_Poti_icon.png")
var jumpPotionIcon: Texture = preload("res://assets/potions/jump-potion/Jump_Poti_icon.png")
var speedPotionIcon: Texture = preload("res://assets/potions/speed-potion/Speed_Poti_icon.png")

var selectedPotionType := PotionTypes.PotionType.None;

var showPotionTimer = false;

func _ready() -> void:
	_configure_timer();

func _process(_delta: float) -> void:
	_process_potions_timer();

func _enter_tree() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);
	PlayerPotions.selectedPotionChanged.connect(_on_selected_potion_changed);
	PlayerPotions.potionUsed.connect(_on_potion_used);

# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("combineSelection"):
# 		_on_combine_selection_pressed()

func getNumberOfPotionsByType(potionType: PotionTypes.PotionType) -> String:
	var potionSize = PlayerPotions.potionsDictionary.get(potionType);
	if potionSize == 0 or potionSize == null:
		return ""
	else:
		return str(potionSize)

func evaluateText(potionType: PotionTypes.PotionType) -> void:
	match(potionType):
		PotionTypes.PotionType.Jump:
			potionIconTexture.texture = jumpPotionIcon
		PotionTypes.PotionType.Speed:
			potionIconTexture.texture = speedPotionIcon
		PotionTypes.PotionType.Fire:
			potionIconTexture.texture = firePotionIcon
		_:
			potionIconTexture.texture = null

func evaluateNumber(potionType: PotionTypes.PotionType) -> void:
	numberOfPotions.text = getNumberOfPotionsByType(potionType)

func _configure_timer() -> void:
	potionsTimer.one_shot = true;
	potionsTimer.connect("timeout", _on_potions_timer_timeout)

func _process_potions_timer() -> void:
	if not potionsTimer.is_stopped():
		potionsTimerLabel.text = str(int(potionsTimer.time_left))

func _on_potions_timer_timeout() -> void:
	potionsTimerLabel.visible = false;

func _on_potions_change(_potions: Dictionary):
	evaluateNumber(selectedPotionType)

func _on_selected_potion_changed(potionType: PotionTypes.PotionType) -> void:
	selectedPotionType = potionType;
	evaluateNumber(potionType);
	evaluateText(potionType);

func _on_potion_used(potionType: PotionTypes.PotionType) -> void:
	var potionConfig = PotionsConfig.get_potion_properties(potionType);
	if potionConfig:
		potionsTimer.wait_time = potionConfig.lifeTime;
		potionsTimerLabel.visible = true;
		potionsTimer.start()

func _on_combine_selection_pressed() -> void:
	if not PlayerPotions.areThereAnyPotions():
		return
	
	PotionMergerService.selectedPotionToMerge = selectedPotionType;
