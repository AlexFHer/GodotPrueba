class_name Potion extends Resource

const PotionType = preload("res://assets/potions/shared/models/potion-types.gd").PotionType

@export var type: PotionType;
@export var expireTime = 30;
