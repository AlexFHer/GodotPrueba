extends Node3D
class_name FireAbilityAura

@export var fade_after_stop_seconds := 0.45

var _particles: Array[GPUParticles3D] = []
var _stop_generation := 0
@onready var _light: OmniLight3D = $WarmFireLight

func _ready() -> void:
	_particles = _collect_particles(self)
	stop_immediate()

func start() -> void:
	_stop_generation += 1
	visible = true
	if _light != null:
		_light.visible = true
	for particle_system in _particles:
		particle_system.restart()
		particle_system.emitting = true

func stop() -> void:
	_stop_generation += 1
	var stop_generation := _stop_generation
	for particle_system in _particles:
		particle_system.emitting = false
	if _light != null:
		_light.visible = false

	await get_tree().create_timer(fade_after_stop_seconds, false).timeout
	if stop_generation == _stop_generation:
		visible = false

func stop_immediate() -> void:
	_stop_generation += 1
	visible = false
	if _light != null:
		_light.visible = false
	for particle_system in _particles:
		particle_system.emitting = false

func _collect_particles(root: Node) -> Array[GPUParticles3D]:
	var found_particles: Array[GPUParticles3D] = []
	for child in root.get_children():
		if child is GPUParticles3D:
			found_particles.append(child)
		found_particles.append_array(_collect_particles(child))
	return found_particles