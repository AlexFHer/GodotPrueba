class_name PotionsData extends Node

const PotionEnum = preload("res://assets/potions/resources/potion-types.gd").PotionType

var potions: Array[Potion] = [];
signal potionsChanged;

func isThereAnyPotionOfType(potionType: PotionEnum) -> bool:
	for potion in potions: 
		if potion.type == potionType: 
			return true 
	return false

func addPotion(potion: Potion):
	potions.append(potion);
	potionsChanged.emit(potions)

func removeOnePotionByType(potionType: PotionEnum):
	for potion in potions: 
		if potion.type == potionType: 
			potions.erase(potion) 
			break
