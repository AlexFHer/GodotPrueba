class_name Potion extends Resource

const PotionType = preload("res://resources/potions/potion-types.gd").PotionType

@export var name = ""
@export var spriteUrl = ""
@export var type: PotionType;

# do a function
