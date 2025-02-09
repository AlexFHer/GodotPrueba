extends Node

@onready var shootPos = $ShootPosition;
@onready var rig = %Rig;
var fireProjectile := preload("res://assets/projectiles/fire-projectile/fire-projectile.tscn");

var canShoot = false;

func _on_potions_manager_potion_used(potion: Potion) -> void:
	if potion.type == PotionProperties.PotionType.Fire:
		var instance = fireProjectile.instantiate();
		add_child(instance)
		instance.position = shootPos.position;
		instance.global_rotation = rig.global_rotation;
