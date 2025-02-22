class_name PotionsData extends Node

# Diccionario Dictionary[Tipo de pocion, numero de pociones]
var potionsDictionary: Dictionary = {}
var selectedPotionType: PotionTypes.PotionType = PotionTypes.PotionType.None;

signal potionsChanged(dictionary: Dictionary);
signal selectedPotionChanged(potionType: PotionTypes.PotionType);
signal potionUsed(potionType: PotionTypes.PotionType);

func isThereAnyPotionOfType(potionType: PotionTypes.PotionType) -> bool:
	return potionsDictionary.get(potionType, 0) > 0;

func addPotion(potionType: PotionTypes.PotionType):
	if not potionsDictionary.has(potionType):
		potionsDictionary[potionType] = 0;
	potionsDictionary[potionType] += 1;
	print(potionsDictionary);
	_emitPotions()
	_checkIfPotionShouldBeSelectedOnPickUp(potionType);

func removeOnePotionByType(potionType: PotionTypes.PotionType):
	if not potionsDictionary.has(potionType):
		return
	
	potionsDictionary[potionType] -= 1;
	
	if potionsDictionary[potionType] == 0:
		potionsDictionary.erase(potionType)
	
	_emitPotions()

func removeAllPotions() -> void:
	potionsDictionary.clear()
	_emitPotions()

func areThereAnyPotions() -> bool:
	for potionKey in potionsDictionary.keys():
		if potionKey:
			return true;
	return false

func getFirstPotion() -> PotionTypes.PotionType:
	if not areThereAnyPotions():
		return PotionTypes.PotionType.None;
	
	return potionsDictionary.keys()[0]

func toggleLeftPotion() -> void:
	var lastPotion = _getLastPotionType(selectedPotionType);
	selectPotion(lastPotion);

func toggleRightPotion() -> void:
	var nextPotion = _getNextPotionType(selectedPotionType);
	selectPotion(nextPotion);

func selectPotion(potionType: PotionTypes.PotionType) -> void:
	selectedPotionType = potionType;
	selectedPotionChanged.emit(potionType);

func usePotion() -> void:
	print("use potion");
	print(isThereAnyPotionOfType(selectedPotionType))
	print(potionsDictionary)
	if not isThereAnyPotionOfType(selectedPotionType):
		return
	potionUsed.emit(selectedPotionType);
	removeOnePotionByType(selectedPotionType);
	_checkPotionsAvailability();

func _checkPotionsAvailability() -> void:
	if not areThereAnyPotions():
		_unselectPotion();
		
	if potionsDictionary.keys().size() == 1:
		selectPotion(getFirstPotion())

func _unselectPotion() -> void:
	selectPotion(PotionTypes.PotionType.None)

func _getLastPotionType(currentType: PotionTypes.PotionType) -> PotionTypes.PotionType:
	if not areThereAnyPotions():
		return PotionTypes.PotionType.None;
	
	if currentType == PotionTypes.PotionType.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex != -1:
		var doesItExist = foundTypeIndex - 1 < keys.size()
		if doesItExist:
			return keys[foundTypeIndex - 1]
			
	return keys[keys.size() - 1]

func _getNextPotionType(currentType: PotionTypes.PotionType) -> PotionTypes.PotionType:
	if not areThereAnyPotions():
		return PotionTypes.PotionType.None;
	
	if currentType == PotionTypes.PotionType.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex != -1:
		var doesItExist = foundTypeIndex + 1 < keys.size()
		if doesItExist:
			return keys[foundTypeIndex + 1]
			
	return keys[0]

func _emitPotions() -> void:
	potionsChanged.emit(potionsDictionary);


func _checkIfPotionShouldBeSelectedOnPickUp(pickedUpPotion: PotionTypes.PotionType) -> void:
	if selectedPotionType == PotionTypes.PotionType.None:
		selectPotion(pickedUpPotion)
	
