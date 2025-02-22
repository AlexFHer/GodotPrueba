class_name PotionsData extends Node

# Diccionario Dictionary[Tipo de pocion, numero de pociones]
var potionsDictionary: Dictionary = {}
var selectedPotionType: PotionProperties.PotionType = PotionProperties.PotionType.None;

signal potionsChanged(dictionary: Dictionary);
signal selectedPotionChanged(potionType: PotionProperties.PotionType);
signal potionUsed(potionType: PotionProperties.PotionType);

func isThereAnyPotionOfType(potionType: PotionProperties.PotionType) -> bool:
	return potionsDictionary.get(potionType, 0) > 0;

func addPotion(potionType: PotionProperties.PotionType):
	if not potionsDictionary.has(potionType):
		potionsDictionary[potionType] = 0;
	potionsDictionary[potionType] += 1;
	print(potionsDictionary);
	_emitPotions()
	_checkIfPotionShouldBeSelectedOnPickUp(potionType);

func removeOnePotionByType(potionType: PotionProperties.PotionType):
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

func getFirstPotion() -> PotionProperties.PotionType:
	if not areThereAnyPotions():
		return PotionProperties.PotionType.None;
	
	return potionsDictionary.keys()[0]

func toggleLeftPotion() -> void:
	var lastPotion = _getLastPotionType(selectedPotionType);
	selectPotion(lastPotion);

func toggleRightPotion() -> void:
	var nextPotion = _getNextPotionType(selectedPotionType);
	selectPotion(nextPotion);

func selectPotion(potionType: PotionProperties.PotionType) -> void:
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
	selectPotion(PotionProperties.PotionType.None)

func _getLastPotionType(currentType: PotionProperties.PotionType) -> PotionProperties.PotionType:
	if not areThereAnyPotions():
		return PotionProperties.PotionType.None;
	
	if currentType == PotionProperties.PotionType.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex != -1:
		var doesItExist = foundTypeIndex - 1 < keys.size()
		if doesItExist:
			return keys[foundTypeIndex - 1]
			
	return keys[keys.size() - 1]

func _getNextPotionType(currentType: PotionProperties.PotionType) -> PotionProperties.PotionType:
	if not areThereAnyPotions():
		return PotionProperties.PotionType.None;
	
	if currentType == PotionProperties.PotionType.None:
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


func _checkIfPotionShouldBeSelectedOnPickUp(pickedUpPotion: PotionProperties.PotionType) -> void:
	if selectedPotionType == PotionProperties.PotionType.None:
		selectPotion(pickedUpPotion)
	
