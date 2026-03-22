class_name PotionsData extends Node

# Diccionario Dictionary[Tipo de pocion, numero de pociones]
var potionsDictionary: Dictionary[PotionTypes.PotionType, int] = {}
var selectedLeftPotionType: PotionTypes.PotionType = PotionTypes.PotionType.None;
var selectedRightPotionType: PotionTypes.PotionType = PotionTypes.PotionType.None;

# Mantiene compatibilidad con scripts que aun usan una sola seleccion.
var selectedPotionType: PotionTypes.PotionType = PotionTypes.PotionType.None;

var canDrinkPotion := true;

signal potionsChanged(dictionary: Dictionary[PotionTypes.PotionType, int]);
signal selectedLeftPotionChanged(potionType: PotionTypes.PotionType);
signal selectedRightPotionChanged(potionType: PotionTypes.PotionType); 
signal selectedPotionChanged(potionType: PotionTypes.PotionType);
signal potionUsed(potionType: PotionTypes.PotionType);
signal potionEffectFinished(potionType: PotionTypes.PotionType);

func isThereAnyPotionOfType(potionType: PotionTypes.PotionType) -> bool:
	return potionsDictionary.get(potionType, 0) > 0;

func addPotion(potionType: PotionTypes.PotionType):
	if not potionsDictionary.has(potionType):
		potionsDictionary[potionType] = 0;
	potionsDictionary[potionType] += 1;
	_emitPotions()
	_checkIfPotionShouldBeSelectedOnPickUp(potionType);

func removeOnePotionByType(potionType: PotionTypes.PotionType):
	if not potionsDictionary.has(potionType):
		return
	
	potionsDictionary[potionType] -= 1;
	
	if potionsDictionary[potionType] == 0:
		potionsDictionary.erase(potionType)
	
	_emitPotions()
	_checkPotionsAvailability();

func removeAllPotions() -> void:
	potionsDictionary.clear()
	_emitPotions()
	_checkPotionsAvailability();

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
	var lastPotion = _getLastPotionType(selectedLeftPotionType);
	selectLeftPotion(lastPotion);

func toggleRightPotion() -> void:
	var nextPotion = _getNextPotionType(selectedRightPotionType);
	selectRightPotion(nextPotion);

func selectLeftPotion(potionType: PotionTypes.PotionType) -> void:
	selectedLeftPotionType = potionType;
	selectedLeftPotionChanged.emit(potionType);

func selectRightPotion(potionType: PotionTypes.PotionType) -> void:
	selectedRightPotionType = potionType;
	selectedRightPotionChanged.emit(potionType);
	_syncLegacySelectedPotionType();

func selectPotion(potionType: PotionTypes.PotionType) -> void:
	# Compatibilidad hacia atras: seleccion simple = slot derecho.
	selectRightPotion(potionType);

func usePotion() -> void:
	# Compatibilidad hacia atras: usar pocion usa el slot derecho.
	useRightPotion();

func useLeftPotion() -> void:
	_usePotionByType(selectedLeftPotionType);

func useRightPotion() -> void:
	_usePotionByType(selectedRightPotionType);

func _usePotionByType(potionType: PotionTypes.PotionType) -> void:
	if not isThereAnyPotionOfType(potionType):
		return
	potionUsed.emit(potionType);
	emitWhenPotionFinish(potionType);
	removeOnePotionByType(potionType);

func _checkPotionsAvailability() -> void:
	if not areThereAnyPotions():
		_unselectPotion();
		return

	if potionsDictionary.keys().size() == 1:
		var onlyPotionType = getFirstPotion()
		selectLeftPotion(onlyPotionType)
		selectRightPotion(onlyPotionType)
		return

	if not isThereAnyPotionOfType(selectedLeftPotionType):
		selectLeftPotion(getFirstPotion())

	if not isThereAnyPotionOfType(selectedRightPotionType):
		selectRightPotion(getFirstPotion())

func _unselectPotion() -> void:
	selectLeftPotion(PotionTypes.PotionType.None)
	selectRightPotion(PotionTypes.PotionType.None)

func _getLastPotionType(currentType: PotionTypes.PotionType) -> PotionTypes.PotionType:
	if not areThereAnyPotions():
		return PotionTypes.PotionType.None;
	
	if currentType == PotionTypes.PotionType.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex == -1:
		return keys[0]

	return keys[(foundTypeIndex - 1 + keys.size()) % keys.size()]

func _getNextPotionType(currentType: PotionTypes.PotionType) -> PotionTypes.PotionType:
	if not areThereAnyPotions():
		return PotionTypes.PotionType.None;
	
	if currentType == PotionTypes.PotionType.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex == -1:
		return keys[0]

	return keys[(foundTypeIndex + 1) % keys.size()]

func _emitPotions() -> void:
	potionsChanged.emit(potionsDictionary);


func _checkIfPotionShouldBeSelectedOnPickUp(pickedUpPotion: PotionTypes.PotionType) -> void:
	if selectedLeftPotionType == PotionTypes.PotionType.None:
		selectLeftPotion(pickedUpPotion)

	if selectedRightPotionType == PotionTypes.PotionType.None:
		selectRightPotion(pickedUpPotion)

func _syncLegacySelectedPotionType() -> void:
	selectedPotionType = selectedRightPotionType;
	selectedPotionChanged.emit(selectedPotionType);
	
func emitWhenPotionFinish(potionType: PotionTypes.PotionType) -> void:
	canDrinkPotion = false;
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime;
	await get_tree().create_timer(lifeTime).timeout
	potionEffectFinished.emit(potionType);
	canDrinkPotion = true;
