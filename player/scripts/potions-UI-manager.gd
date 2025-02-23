extends Control

@onready var label: Label = $Name
@onready var numberOfPotions: Label = $NumberOfPotions
@onready var potionsTimer: Timer = %PotionsTimer
@onready var potionsTimerLabel: Label = %PotionTimerLabel

var selectedPotionType = PotionTypes.PotionType.None;

var showPotionTimer = false;

func _ready() -> void:
	_configure_timer();

func _process(_delta: float) -> void:
	_process_potions_timer();

func _enter_tree() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change);
	PlayerPotions.selectedPotionChanged.connect(_on_selected_potion_changed);
	PlayerPotions.potionUsed.connect(_on_potion_used);

func getNumberOfPotionsByType(potionType: PotionTypes.PotionType) -> String:
	var potionSize = PlayerPotions.potionsDictionary.get(potionType);
	if potionSize == 0:
		return ""
	else:
		return str(potionSize)

func evaluateText(potionType: PotionTypes.PotionType) -> void:
	match(potionType):
		PotionTypes.PotionType.Jump:
			label.text = "jump_potion_ui_text"
		PotionTypes.PotionType.Speed:
			label.text = "speed_potion_ui_text"
		PotionTypes.PotionType.Fire:
			label.text = "fire_potion_ui_text"
		_:
			label.text = "No potions left"

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
