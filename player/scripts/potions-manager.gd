extends Node

const PotionEnum = preload("res://assets/potions/shared/models/potion-types.gd").PotionType

var selectedPotionType: PotionEnum;

signal potionUsed;
signal selectedPotionTypeChanged(potionType: PotionEnum);

func _init() -> void:
	PlayerPotions.potionsChanged.connect(_on_potions_change)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggleLeftPotion"):
		toggleLeftPotion()
	
	if Input.is_action_just_pressed("toggleRightPotion"):
		toggleRightPotion()
	
	if Input.is_action_just_pressed("usePotion"):
		usePotion()

func usePotion() -> void:
	if selectedPotionType == PotionEnum.None:
		return;
	
	if not PlayerPotions.isThereAnyPotionOfType(selectedPotionType):
		return;
	
	#TODO: Cambiar esto mas adelante para que no tire de una pocion en concreto si no que
	# coja la configuracion del RES el life time y demas.
	var potion = PlayerPotions.potionsDictionary.get(selectedPotionType)[0]
	
	potionUsed.emit(potion);
	PlayerPotions.removeOnePotionByType(selectedPotionType)
	if not PlayerPotions.isThereAnyPotionOfType(selectedPotionType):
		selectPotion(PlayerPotions.getFirstPotion())
	

func selectPotion(potionType: PotionEnum):	
	selectedPotionType = potionType
	selectedPotionTypeChanged.emit(potionType)

func toggleLeftPotion() -> void:
	var nextPotionType = PlayerPotions.getLastPotionType(selectedPotionType)
	selectPotion(nextPotionType)

func toggleRightPotion() -> void:
	var nextPotionType = PlayerPotions.getNextPotionType(selectedPotionType)
	print(nextPotionType)
	selectPotion(nextPotionType)

func unselectPotion():
	selectPotion(PotionEnum.None)

func _on_potions_change(potionDictionary: Dictionary) -> void:
	if potionDictionary.keys().size() == 0:
		unselectPotion();
		
	if potionDictionary.keys().size() == 1:
		selectPotion(potionDictionary.keys()[0])
