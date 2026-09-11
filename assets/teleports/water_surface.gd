extends MeshInstance3D

const SPLASH = preload("res://assets/teleports/water_splash.tscn")
var _ripple: Tween

func play_entry_splash() -> void:
	var water_material := material_override as ShaderMaterial
	if water_material == null:
		return
	if _ripple != null:
		_ripple.kill()
	water_material.set_shader_parameter("impact_progress", 0.0)
	_ripple = create_tween()
	_ripple.tween_method(func(progress: float) -> void:
		water_material.set_shader_parameter("impact_progress", progress), 0.0, 1.0, 1.0)
	var splash := SPLASH.instantiate() as CPUParticles3D
	add_child(splash)
	var tint: Variant = water_material.get_shader_parameter("water_color")
	if tint is Color:
		splash.color = tint.lerp(Color.WHITE, 0.35)
	splash.finished.connect(splash.queue_free)
	splash.emitting = true
