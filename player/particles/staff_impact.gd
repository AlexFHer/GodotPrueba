extends Node3D

@onready var wave: MeshInstance3D = $Wave

func _ready() -> void:
	var material := wave.material_override.duplicate() as ShaderMaterial
	wave.material_override = material
	var animation := create_tween()
	animation.tween_method(func(progress: float) -> void:
		material.set_shader_parameter(&"progress", progress), 0.0, 1.0, 0.3)
	animation.tween_callback(wave.hide)
	animation.tween_interval(0.4)
	animation.tween_callback(queue_free)
