extends Node

@onready var fire_life_particle: GPUParticles3D = %FirePotma

const FULL_LIFE_TIME := 0.7;
const HALF_LIFE_TIME := 0.05;
const DEFAULT_SPEED_SCALE := 1.0;
const HALF_SPEED_SCALE := 0.5;

func _on_main_character_life_changed(newLife: int) -> void:
	if newLife > 1:
		fire_life_particle.visible = true
	else:
		fire_life_particle.visible = false

	if newLife == 3:
		fire_life_particle.lifetime = FULL_LIFE_TIME
		fire_life_particle.speed_scale = DEFAULT_SPEED_SCALE
	elif newLife == 2:
		fire_life_particle.lifetime = HALF_LIFE_TIME
		fire_life_particle.speed_scale = HALF_SPEED_SCALE
