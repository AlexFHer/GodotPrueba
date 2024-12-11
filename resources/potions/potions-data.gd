class_name PotionsData extends Resource

const PotionEnum = preload("res://resources/potions/potion-types.gd").PotionType

@export var potions: Array[Potion] = [];

func addPotion(potion: Potion):
	potions.append(potion);

func removeOnePotionByType(potionType: PotionEnum):
	for potion in potions: 
		if potion.type == potionType: 
			potions.erase(potion) 
		break
