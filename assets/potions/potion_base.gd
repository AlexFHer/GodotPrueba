extends Area3D

class_name PotionBase

@export var potionType: PotionTypes.PotionType;

const rotationSpeed = 1.5;

func _process(delta: float) -> void:
	rotate_y(rotationSpeed * delta);
