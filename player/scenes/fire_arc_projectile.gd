class_name FireArcProjectile
extends Area3D

const COMBO_INCLINATION_DEGREES := [-35.0, 35.0, 90.0]
const COMBO_SWEEP_DIRECTIONS := [1.0, -1.0, 1.0]

@export_range(0.0, 30.0, 0.1) var speed := 16.0
@export_range(0.1, 5.0, 0.05) var lifetime := 0.8

@onready var _visual: MeshInstance3D = %Visual

var _age := 0.0
var _material: ShaderMaterial
var _damaged_targets: Array[Node] = []


func _ready() -> void:
	_material = _visual.get_active_material(0) as ShaderMaterial
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_damage_existing_overlaps_after_physics()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	global_position += -global_transform.basis.z.normalized() * speed * delta
	if _material != null:
		_material.set_shader_parameter(&"life_progress", _age / lifetime)


func configure_for_combo_step(combo_step: int) -> void:
	var safe_step := clampi(combo_step, 0, COMBO_INCLINATION_DEGREES.size() - 1)
	rotate_object_local(
		Vector3.BACK,
		deg_to_rad(COMBO_INCLINATION_DEGREES[safe_step])
	)
	if _material != null:
		_material.set_shader_parameter(
			&"sweep_direction",
			COMBO_SWEEP_DIRECTIONS[safe_step]
		)


func _on_body_entered(body: Node3D) -> void:
	_damage_target(body)


func _on_area_entered(area: Area3D) -> void:
	_damage_target(area)


func _damage_existing_overlaps_after_physics() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return

	for body in get_overlapping_bodies():
		_damage_target(body)
	for area in get_overlapping_areas():
		_damage_target(area)


func _damage_target(target: Node) -> void:
	if target.is_in_group("MainPlayer") or _damaged_targets.has(target):
		return
	if not target.is_in_group("CanGetHit") or not target.has_method("get_hit"):
		return

	_damaged_targets.append(target)
	target.get_hit()
