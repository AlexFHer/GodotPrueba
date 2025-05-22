extends Node

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var potmaSounds: PotmaSounds = %PotmaSounds

var current_active_potion: PotionTypes.PotionType = PotionTypes.PotionType.None

func _ready() -> void:
	PlayerPotions.potionEffectFinished.connect(_on_potion_effect_finished)
	PlayerPotions.potionUsed.connect(_on_potion_used)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggleLeftPotion"):
		PlayerPotions.toggleLeftPotion();
	
	if Input.is_action_just_pressed("toggleRightPotion"):
		PlayerPotions.toggleRightPotion();
	
	if Input.is_action_just_pressed("usePotion"):
		usePotion()

func usePotion() -> void:
	if PlayerPotions.selectedPotionType == PotionTypes.PotionType.None:
		return;
	
	var selectedPotionToMerge = PotionMergerService.selectedPotionToMerge;
	if selectedPotionToMerge != PotionTypes.PotionType.None:
		mergePotion();
	else:
		drinkPotion();

func mergePotion() -> void:
	var selectedPotionToMerge = PotionMergerService.selectedPotionToMerge;
	if selectedPotionToMerge == PlayerPotions.selectedPotionType:
		PlayerPotions.usePotion()
	else:
		pass

func _on_drink_animation_finished() -> void:
	potmaSounds.drinkSoundAudioStream.play();

func drinkPotion() -> void:
	if current_active_potion != PotionTypes.PotionType.None:
		return;

	PlayerPotions.usePotion();
	_animation_tree.set("parameters/DrinkOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
 

func play_drink_animation() -> void:
	_animation_tree.set("parameters/DrinkOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_potion_used(potion_type: PotionTypes.PotionType) -> void:
	current_active_potion = potion_type

func _on_potion_effect_finished(_potion_type: PotionTypes.PotionType) -> void:
	current_active_potion = PotionTypes.PotionType.None