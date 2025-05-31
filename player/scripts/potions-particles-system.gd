class_name PotionsParticleSystem extends Node

var fire_particle: PackedScene = preload("res://player/particles/FirePotion_Particles.tscn");
var jump_particle: PackedScene = preload("res://player/particles/JumpPotion_Particles.tscn");
var speed_particle: PackedScene = preload("res://player/particles/SpeedPotion_Particles.tscn");

var particles: Dictionary[PotionTypes.PotionType, PackedScene] = {
	PotionTypes.PotionType.Fire: fire_particle,
	PotionTypes.PotionType.Jump: jump_particle,
	PotionTypes.PotionType.Speed: speed_particle
};

func _play_particles(potionType: PotionTypes.PotionType) -> void:
	if potionType in particles:
		var particle_instance = particles[potionType].instantiate()
		add_child(particle_instance)
	else:
		push_error("No particles found for potion type: " + str(potionType))

