extends Area3D

class_name PotionBase

@export var potion: Potion;
@export var potionType: PotionProperties.PotionType;

const rotationSpeed = 1.5;

func _process(delta: float) -> void:
	rotate_y(rotationSpeed * delta);
