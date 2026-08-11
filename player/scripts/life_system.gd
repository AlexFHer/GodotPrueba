extends Node

@onready var fire_life_particle: GPUParticles3D = %FirePotma

const FULL_LIFE_TIME := 0.7;
const HALF_LIFE_TIME := 0.35;
		
func _on_main_character_life_changed(newLife: int) -> void:
	if newLife > 1:
		fire_life_particle.emitting = true
	else:
		fire_life_particle.emitting = false

	if newLife == 3:
		fire_life_particle.lifetime = FULL_LIFE_TIME
	elif newLife == 2:
		fire_life_particle.lifetime = HALF_LIFE_TIME
