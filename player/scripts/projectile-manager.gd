extends Node

@onready var shootPos = $"../Rig/ShootPosition";
@onready var rig = %Rig;


var canShoot = false;

func _on_potions_manager_potion_used(potion: Potion) -> void:
	if potion.type == PotionProperties.PotionType.Fire:
		var instance = FireProjectile.new_fire_projectile();
		instance.position = shootPos.global_position;
		instance.rotation = rig.rotation;
		get_tree().root.add_child(instance)
