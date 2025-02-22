extends Node

@onready var shootPos = $"../Rig/ShootPosition";
@onready var rig = %Rig;

var canShoot = false;

func _init() -> void:
	PlayerPotions.potionUsed.connect(_on_potions_manager_potion_used)

func _on_potions_manager_potion_used(potionType: PotionProperties.PotionType) -> void:
	if potionType == PotionProperties.PotionType.Fire:
		var instance = FireProjectile.new_fire_projectile();
		instance.position = shootPos.global_position;
		instance.rotation = rig.rotation;
		get_tree().root.add_child(instance)
