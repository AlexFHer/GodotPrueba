extends Area3D
const OPEN_ANIMATION_NAME = "Abrir"

@export var animation_player: AnimationPlayer
@export var lightning_meshes: Array[MeshInstance3D] = []
@export_range(0.2, 3.0) var charge_duration: float = 0.9

var is_open: bool = false
var _is_charging: bool = false

func _ready() -> void:
	for mesh in lightning_meshes:
		mesh.hide()

func _on_body_entered(body: Node3D) -> void:
	if body is MainPlayer:
		_open_flower()

func _open_flower() -> void:
	if is_open or _is_charging:
		return
	_is_charging = true
	var charge := create_tween().set_parallel(true)
	charge.tween_interval(charge_duration)
	for index in lightning_meshes.size():
		var mesh := lightning_meshes[index]
		var material := mesh.material_override as ShaderMaterial
		var delay := charge_duration * 0.35 * float(index) / maxi(lightning_meshes.size() - 1, 1)
		material.set_shader_parameter("progress", 0.0)
		material.set_shader_parameter("effect_time", 0.0)
		mesh.show()
		charge.tween_property(material, "shader_parameter/progress", 1.0, charge_duration * 0.65).set_delay(delay)
		charge.tween_property(material, "shader_parameter/effect_time", charge_duration, charge_duration)
	await charge.finished
	for mesh in lightning_meshes:
		mesh.hide()
	_is_charging = false
	is_open = true
	animation_player.play(OPEN_ANIMATION_NAME)
