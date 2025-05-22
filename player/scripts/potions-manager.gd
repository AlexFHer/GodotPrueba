extends Node

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var potmaSounds: PotmaSounds = %PotmaSounds

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggleLeftPotion"):
		print("toggleLeftPotion")
		PlayerPotions.toggleLeftPotion();
	
	if Input.is_action_just_pressed("toggleRightPotion"):
		print("toggleRightPotion")
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
	PlayerPotions.usePotion();
	_animation_tree.set("parameters/DrinkOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
 

func play_drink_animation() -> void:
	_animation_tree.set("parameters/DrinkOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)