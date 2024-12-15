class_name Potion extends Resource

const PotionType = preload("res://assets/potions/shared/models/potion-types.gd").PotionType

@export var name = "";
@export var spriteUrl = "";
@export var type: PotionType;
