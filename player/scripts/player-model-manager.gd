extends Node3D

const POTION_EFFECT_BOTTOM_Y := -0.025
const POTION_EFFECT_TOP_Y := 1.04

var bodyBaseColor: CompressedTexture2D = load("res://player/materials/Potma2_PotmaMat_Base_color.png");
var bodyPotionMask: CompressedTexture2D = load("res://player/materials/PotmaMat_Mask.png");
var potionDurationShader: Shader = preload("res://player/materials/shaders/potion_duration_body.gdshader");

@onready var bodyMeshNode: MeshInstance3D = $Armature/Potma2_0/ArmaturePotma/Skeleton3D/Potma;

@onready var potionPlaceHolder: MeshInstance3D = $Armature/Potma/Armature_Potma/Skeleton3D/Poti_placeHolder

var currentPotion: PotionTypes.PotionType = PotionTypes.PotionType.None
var potionEffectMaterial: ShaderMaterial;
var originalBodyMaterialOverride: Material;
var effectTimeLeft := 0.0;
var effectDuration := 0.0;
var fullEffectFramePending := false;

func _ready() -> void:
	PlayerPotions.potionUsed.connect(_on_potion_used);
	PlayerPotions.potionEffectFinished.connect(_on_potion_effect_finished);
	_prepare_potion_height_mesh()
	_setup_potion_effect_material()

func _process(delta: float) -> void:
	if currentPotion == PotionTypes.PotionType.None:
		return

	effectTimeLeft = max(effectTimeLeft - delta, 0.0)
	potionEffectMaterial.set_shader_parameter("effect_time", effectDuration - effectTimeLeft)
	if fullEffectFramePending:
		fullEffectFramePending = false
		potionEffectMaterial.set_shader_parameter("potion_progress", 1.0)
		return

	_update_potion_progress()
	if effectTimeLeft == 0.0:
		_clear_potion_effect()


# This callback is used when drink animation events are wired from the animation player.
func on_potion_drink_animation_finished() -> void:
	pass

func _on_potion_used(potionType: PotionTypes.PotionType) -> void:
	currentPotion = potionType
	var potionProperties = PotionsConfig.get_potion_properties(potionType)
	if potionProperties == null:
		_clear_potion_effect()
		return

	effectDuration = potionProperties.lifeTime
	effectTimeLeft = effectDuration
	fullEffectFramePending = true
	_set_potion_effect_colors(potionType)
	potionEffectMaterial.set_shader_parameter("effect_time", 0.0)
	potionEffectMaterial.set_shader_parameter("potion_strength", 1.0)
	potionEffectMaterial.set_shader_parameter("potion_progress", 1.0)
	bodyMeshNode.set_surface_override_material(0, potionEffectMaterial)


func _set_potion_effect_colors(potionType: PotionTypes.PotionType) -> void:
	var base_type := potionType
	var secondary_type := PotionTypes.PotionType.None
	match potionType:
		PotionTypes.PotionType.JumpAndFire:
			base_type = PotionTypes.PotionType.Jump
			secondary_type = PotionTypes.PotionType.Fire
		PotionTypes.PotionType.JumpAndSpeed:
			base_type = PotionTypes.PotionType.Jump
			secondary_type = PotionTypes.PotionType.Speed
		PotionTypes.PotionType.SpeedAndFire:
			base_type = PotionTypes.PotionType.Speed
			secondary_type = PotionTypes.PotionType.Fire
	potionEffectMaterial.set_shader_parameter("potion_color", PotionsConfig.get_potion_color(base_type))
	potionEffectMaterial.set_shader_parameter("secondary_color", PotionsConfig.get_potion_color(secondary_type))
	potionEffectMaterial.set_shader_parameter("combined_potion", secondary_type != PotionTypes.PotionType.None)


func _on_player_selected_potion_changed(potionType: PotionTypes.PotionType):
	if currentPotion == PotionTypes.PotionType.None:
		potionEffectMaterial.set_shader_parameter("potion_color", PotionsConfig.get_potion_color(potionType))
	
func _setup_potion_effect_material() -> void:
	originalBodyMaterialOverride = bodyMeshNode.get_surface_override_material(0)
	potionEffectMaterial = ShaderMaterial.new()
	potionEffectMaterial.shader = potionDurationShader
	potionEffectMaterial.set_shader_parameter("albedo", bodyBaseColor)
	potionEffectMaterial.set_shader_parameter("potion_mask", bodyPotionMask)
	potionEffectMaterial.set_shader_parameter("potion_color", Color.WHITE)
	potionEffectMaterial.set_shader_parameter("potion_progress", 0.0)
	potionEffectMaterial.set_shader_parameter("potion_strength", 0.0)

func _prepare_potion_height_mesh() -> void:
	var source_mesh := bodyMeshNode.mesh as ArrayMesh
	if source_mesh == null:
		push_error("Potion duration effect requires Potma to use an ArrayMesh.")
		return

	var imported_mesh := ImporterMesh.from_mesh(source_mesh)
	var effect_mesh := ArrayMesh.new()
	effect_mesh.resource_name = "%s (Potion Height)" % source_mesh.resource_name
	effect_mesh.resource_local_to_scene = true
	effect_mesh.blend_shape_mode = imported_mesh.get_blend_shape_mode()
	for blend_shape_index in imported_mesh.get_blend_shape_count():
		effect_mesh.add_blend_shape(imported_mesh.get_blend_shape_name(blend_shape_index))

	for surface_index in imported_mesh.get_surface_count():
		var surface_arrays := imported_mesh.get_surface_arrays(surface_index)
		var vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]
		var rest_heights := PackedVector2Array()
		rest_heights.resize(vertices.size())
		for vertex_index in vertices.size():
			var normalized_height := inverse_lerp(
				POTION_EFFECT_BOTTOM_Y,
				POTION_EFFECT_TOP_Y,
				vertices[vertex_index].y
			)
			rest_heights[vertex_index] = Vector2(clampf(normalized_height, 0.0, 1.0), 0.0)
		surface_arrays[Mesh.ARRAY_TEX_UV2] = rest_heights

		var blend_shape_arrays: Array[Array] = []
		for blend_shape_index in imported_mesh.get_blend_shape_count():
			blend_shape_arrays.append(
				imported_mesh.get_surface_blend_shape_arrays(surface_index, blend_shape_index)
			)

		var lods := {}
		for lod_index in imported_mesh.get_surface_lod_count(surface_index):
			lods[imported_mesh.get_surface_lod_size(surface_index, lod_index)] = \
				imported_mesh.get_surface_lod_indices(surface_index, lod_index)

		effect_mesh.add_surface_from_arrays(
			imported_mesh.get_surface_primitive_type(surface_index),
			surface_arrays,
			blend_shape_arrays,
			lods
		)
		effect_mesh.surface_set_material(
			surface_index,
			imported_mesh.get_surface_material(surface_index)
		)
		effect_mesh.surface_set_name(surface_index, imported_mesh.get_surface_name(surface_index))

	effect_mesh.lightmap_size_hint = imported_mesh.get_lightmap_size_hint()
	effect_mesh.custom_aabb = source_mesh.custom_aabb
	if source_mesh.shadow_mesh != null:
		effect_mesh.shadow_mesh = source_mesh.shadow_mesh
	for metadata_name in source_mesh.get_meta_list():
		effect_mesh.set_meta(metadata_name, source_mesh.get_meta(metadata_name))
	bodyMeshNode.mesh = effect_mesh

func _update_potion_progress() -> void:
	if effectDuration <= 0.0:
		potionEffectMaterial.set_shader_parameter("potion_progress", 0.0)
		return

	potionEffectMaterial.set_shader_parameter("potion_progress", effectTimeLeft / effectDuration)

func _clear_potion_effect() -> void:
	effectTimeLeft = 0.0
	effectDuration = 0.0
	fullEffectFramePending = false
	potionEffectMaterial.set_shader_parameter("potion_progress", 0.0)
	potionEffectMaterial.set_shader_parameter("potion_strength", 0.0)
	bodyMeshNode.set_surface_override_material(0, originalBodyMaterialOverride)
	currentPotion = PotionTypes.PotionType.None

func _on_potion_effect_finished(potionType: PotionTypes.PotionType) -> void:
	if currentPotion == potionType:
		_clear_potion_effect()
