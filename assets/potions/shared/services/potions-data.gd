class_name PotionsData extends Node

const PotionEnum = preload("res://assets/potions/shared/models/potion-types.gd").PotionType

# diccionario Dictionary[PotionEnum, Array[Potion]]
var potionsDictionary: Dictionary = {}

signal potionsChanged(Dictionary);

func isThereAnyPotionOfType(potionType: PotionEnum) -> bool:
	return potionsDictionary.get(potionType, []).size() > 0;

func addPotion(potion: Potion):
	var potionData = potionsDictionary.get_or_add(potion.type, []);
	potionData.append(potion)
	emitPotions()

func removeOnePotionByType(potionType: PotionEnum):
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

func getFirstPotion() -> PotionEnum:
	if not areThereAnyPotions():
		return PotionEnum.None;
	
	return potionsDictionary.keys()[0]

func getLastPotionType(currentType: PotionEnum) -> PotionEnum:
	if not areThereAnyPotions():
		return PotionEnum.None;
	
	if currentType == PotionEnum.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex != -1:
		var doesItExist = foundTypeIndex - 1 < keys.size()
		if doesItExist:
			return keys[foundTypeIndex - 1]
			
	return keys[keys.size() - 1]

func getNextPotionType(currentType: PotionEnum) -> PotionEnum:
	if not areThereAnyPotions():
		return PotionEnum.None;
	
	if currentType == PotionEnum.None:
		return potionsDictionary.keys()[0]
	
	var keys = potionsDictionary.keys();
	var foundTypeIndex = keys.find(currentType)
	if foundTypeIndex != -1:
		var doesItExist = foundTypeIndex + 1 < keys.size()
		if doesItExist:
			return keys[foundTypeIndex + 1]
			
	return keys[0]
