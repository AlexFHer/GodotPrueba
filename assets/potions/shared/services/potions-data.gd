class_name PotionsData extends Node


# diccionario Dictionary[PotionEnum, Array[Potion]]
var potionsDictionary: Dictionary = {}

signal potionsChanged(Dictionary);

func isThereAnyPotionOfType(potionType: PotionProperties.PotionType) -> bool:
	return potionsDictionary.get(potionType, []).size() > 0;

func addPotion(potion: Potion):
	var potionData = potionsDictionary.get_or_add(potion.type, []);
	potionData.append(potion)
	emitPotions()

func removeOnePotionByType(potionType: PotionProperties.PotionType):
	var potionData = potionsDictionary.get(potionType);
	if potionData == null:
		return;
	potionData.pop_back()
	if potionData.size() == 0:
		potionsDictionary.erase(potionType)
	emitPotions()

func removeAllPotions() -> void:
	potionsDictionary.clear()

func emitPotions() -> void:
	potionsChanged.emit(potionsDictionary);

func areThereAnyPotions() -> bool:
	for potionArray in potionsDictionary.values():
		if potionArray.size() > 0:
			return true
	return false

func getFirstPotion() -> PotionProperties.PotionType:
	if not areThereAnyPotions():
		return PotionProperties.PotionType.None;
	
	return potionsDictionary.keys()[0]

func getLastPotionType(currentType: PotionProperties.PotionType) -> PotionProperties.PotionType:
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

func getNextPotionType(currentType: PotionProperties.PotionType) -> PotionProperties.PotionType:
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
