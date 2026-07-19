extends Node3D

var bodyBaseColor: CompressedTexture2D = load("res://player/materials/PotmaGradient_Base_color.png");
var potionDurationShader: Shader = preload("res://player/materials/shaders/potion_duration_body.gdshader");

var potionTypeToColorLookUp: Dictionary[PotionTypes.PotionType, Color] = {
	PotionTypes.PotionType.Fire: Color(1.0, 0.12, 0.05),
	PotionTypes.PotionType.Jump: Color(0.2, 0.45, 1.0),
	PotionTypes.PotionType.Speed: Color(0.15, 1.0, 0.25),
	PotionTypes.PotionType.JumpAndFire: Color(0.85, 0.18, 1.0),
	PotionTypes.PotionType.JumpAndSpeed: Color(0.0, 0.95, 1.0),
	PotionTypes.PotionType.SpeedAndFire: Color(1.0, 0.55, 0.0)
}

@onready var bodyMeshNode: MeshInstance3D = $Armature/Potma/Armature_Potma/Skeleton3D/MainBody;

@onready var potionPlaceHolder: MeshInstance3D = $Armature/Potma/Armature_Potma/Skeleton3D/Poti_placeHolder

var currentPotion: PotionTypes.PotionType = PotionTypes.PotionType.None
var potionEffectMaterial: ShaderMaterial;
var effectTimeLeft := 0.0;
var effectDuration := 0.0;

func _ready() -> void:
	PlayerPotions.potionUsed.connect(_on_potion_used);
	PlayerPotions.potionEffectFinished.connect(_on_potion_effect_finished);
	_setup_potion_effect_material()

func _process(delta: float) -> void:
	if currentPotion == PotionTypes.PotionType.None:
		return

	effectTimeLeft = max(effectTimeLeft - delta, 0.0)
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
	potionEffectMaterial.set_shader_parameter("potion_color", potionTypeToColorLookUp.get(potionType, Color.WHITE))
	potionEffectMaterial.set_shader_parameter("potion_strength", 0.75)
	_update_potion_progress()


func _on_player_selected_potion_changed(potionType: PotionTypes.PotionType):
	if currentPotion == PotionTypes.PotionType.None:
		potionEffectMaterial.set_shader_parameter("potion_color", potionTypeToColorLookUp.get(potionType, Color.WHITE))
	
func _setup_potion_effect_material() -> void:
	potionEffectMaterial = ShaderMaterial.new()
	potionEffectMaterial.shader = potionDurationShader
	potionEffectMaterial.set_shader_parameter("albedo", bodyBaseColor)
	potionEffectMaterial.set_shader_parameter("potion_color", Color.WHITE)
	potionEffectMaterial.set_shader_parameter("potion_progress", 0.0)
	potionEffectMaterial.set_shader_parameter("potion_strength", 0.0)
	var bodyBounds := bodyMeshNode.get_aabb()
	potionEffectMaterial.set_shader_parameter("effect_bottom_y", bodyBounds.position.y)
	potionEffectMaterial.set_shader_parameter("effect_top_y", bodyBounds.position.y + bodyBounds.size.y)
	bodyMeshNode.set_surface_override_material(0, potionEffectMaterial)

func _update_potion_progress() -> void:
	if effectDuration <= 0.0:
		potionEffectMaterial.set_shader_parameter("potion_progress", 0.0)
		return

	potionEffectMaterial.set_shader_parameter("potion_progress", effectTimeLeft / effectDuration)

func _clear_potion_effect() -> void:
	effectTimeLeft = 0.0
	effectDuration = 0.0
	potionEffectMaterial.set_shader_parameter("potion_progress", 0.0)
	potionEffectMaterial.set_shader_parameter("potion_strength", 0.0)
	currentPotion = PotionTypes.PotionType.None

func _on_potion_effect_finished(potionType: PotionTypes.PotionType) -> void:
	if currentPotion == potionType:
		_clear_potion_effect()
