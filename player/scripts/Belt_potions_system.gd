extends Node

@export_group("Left slot")
@export var left_potion_visual: Node3D
@export var left_potion_liquid: MeshInstance3D

@export_group("Right slot")
@export var right_potion_visual: Node3D
@export var right_potion_liquid: MeshInstance3D

var _left_liquid_material: ShaderMaterial
var _right_liquid_material: ShaderMaterial

var _pending_left_potion_type: PotionTypes.PotionType = PotionTypes.PotionType.None
var _pending_right_potion_type: PotionTypes.PotionType = PotionTypes.PotionType.None
var _hold_left_visual := false
var _hold_right_visual := false


func _ready() -> void:
	_left_liquid_material = _make_liquid_material_unique(left_potion_liquid)
	_right_liquid_material = _make_liquid_material_unique(right_potion_liquid)

	PlayerPotions.selectedLeftPotionChanged.connect(_on_selected_left_potion_changed)
	PlayerPotions.selectedRightPotionChanged.connect(_on_selected_right_potion_changed)
	_sync_with_selected_potions()


func _make_liquid_material_unique(liquid: MeshInstance3D) -> ShaderMaterial:
	if liquid == null:
		push_error("BeltPotionsSystem requires a liquid mesh for each potion slot.")
		return null

	var source_material := liquid.material_override as ShaderMaterial
	if source_material == null:
		push_error("BeltPotionsSystem requires each liquid mesh to use a ShaderMaterial override.")
		return null

	var unique_material := source_material.duplicate(true) as ShaderMaterial
	liquid.material_override = unique_material
	return unique_material


func _sync_with_selected_potions() -> void:
	_pending_left_potion_type = PlayerPotions.selectedLeftPotionType
	_pending_right_potion_type = PlayerPotions.selectedRightPotionType

	if not _hold_left_visual:
		_update_slot_visual(
			left_potion_visual,
			_left_liquid_material,
			_pending_left_potion_type
		)
	if not _hold_right_visual:
		_update_slot_visual(
			right_potion_visual,
			_right_liquid_material,
			_pending_right_potion_type
		)


func _on_selected_left_potion_changed(potion_type: PotionTypes.PotionType) -> void:
	_pending_left_potion_type = potion_type
	if not _hold_left_visual:
		_update_slot_visual(left_potion_visual, _left_liquid_material, potion_type)


func _on_selected_right_potion_changed(potion_type: PotionTypes.PotionType) -> void:
	_pending_right_potion_type = potion_type
	if not _hold_right_visual:
		_update_slot_visual(right_potion_visual, _right_liquid_material, potion_type)


func _on_potion_drink_started(uses_left_slot: bool, uses_right_slot: bool) -> void:
	_hold_left_visual = uses_left_slot
	_hold_right_visual = uses_right_slot


func _on_potion_drink_finished() -> void:
	_hold_left_visual = false
	_hold_right_visual = false
	_sync_with_selected_potions()


func _update_slot_visual(
		visual: Node3D,
		liquid_material: ShaderMaterial,
		potion_type: PotionTypes.PotionType
) -> void:
	if visual == null:
		return

	visual.visible = potion_type != PotionTypes.PotionType.None
	if not visual.visible or liquid_material == null:
		return

	var potion_color := PotionsConfig.get_potion_color(potion_type)
	liquid_material.set_shader_parameter("liquid_surface_color", potion_color)
	_update_liquid_rim_gradient(liquid_material, potion_color)


func _update_liquid_rim_gradient(material: ShaderMaterial, potion_color: Color) -> void:
	var rim_texture := (
		material.get_shader_parameter("liquid_rim_gradient") as GradientTexture1D
	)
	if rim_texture == null or rim_texture.gradient == null:
		return

	rim_texture.gradient.offsets = PackedFloat32Array([0.0, 1.0])
	rim_texture.gradient.colors = PackedColorArray([
		potion_color.darkened(0.65),
		potion_color
	])
