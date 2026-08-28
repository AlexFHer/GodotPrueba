class_name ComboHitCounterTarget extends CollisionObject3D

const EXPECTED_COMBO_HITS := 3

@export var target_name := "TARGET"
@export var base_color := Color(0.25, 0.65, 1.0)

@onready var _hit_count_label: Label3D = $HitCountLabel
@onready var _target_mesh: MeshInstance3D = $TargetMesh

var hit_count := 0
var _target_material: StandardMaterial3D


func _ready() -> void:
	var source_material := _target_mesh.material_override as StandardMaterial3D
	if source_material != null:
		_target_material = source_material.duplicate() as StandardMaterial3D
		_target_mesh.material_override = _target_material
	_refresh_visuals()


func get_hit() -> void:
	hit_count += 1
	_refresh_visuals()


func reset_hits() -> void:
	hit_count = 0
	_refresh_visuals()


func _refresh_visuals() -> void:
	var status := "READY"
	var feedback_color := base_color
	if hit_count == EXPECTED_COMBO_HITS:
		status = "OK"
		feedback_color = Color(0.25, 1.0, 0.35)
	elif hit_count > EXPECTED_COMBO_HITS:
		status = "EXTRA HIT"
		feedback_color = Color(1.0, 0.2, 0.2)
	elif hit_count > 0:
		status = "KEEP COMBO"
		feedback_color = base_color.lerp(
			Color.WHITE,
			float(hit_count) / float(EXPECTED_COMBO_HITS) * 0.4
		)

	_hit_count_label.text = "%s HITS: %d / %d\n%s" % [
		target_name,
		hit_count,
		EXPECTED_COMBO_HITS,
		status,
	]
	_hit_count_label.modulate = feedback_color
	if _target_material != null:
		_target_material.albedo_color = feedback_color
