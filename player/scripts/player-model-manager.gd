extends Node3D

var bodyBaseColorBlue: CompressedTexture2D = load("res://player/materials/PotmaGradient_Base_color-blue.png");
var bodyBaseColorRed: CompressedTexture2D = load("res://player/materials/PotmaGradient_Base_color-red.png");
var bodyBaseColorGreen: CompressedTexture2D = load("res://player/materials/PotmaGradient_Base_color-green.png");
var bodyBaseColor: CompressedTexture2D = load("res://player/materials/PotmaGradient_Base_color.png");

var potionTypeToTextureLookUp: Dictionary[PotionTypes.PotionType, CompressedTexture2D] = {
	PotionTypes.PotionType.Speed: bodyBaseColorGreen,
	PotionTypes.PotionType.Fire: bodyBaseColorRed,
	PotionTypes.PotionType.Jump: bodyBaseColorBlue
}

@onready var bodyMeshNode: MeshInstance3D = $Armature/Potma/Armature_Potma/Skeleton3D/MainBody;

@onready var potionPlaceHolder: MeshInstance3D = $Armature/Potma/Armature_Potma/Skeleton3D/Poti_placeHolder

var currentPotion: PotionTypes.PotionType = PotionTypes.PotionType.None

func _ready() -> void:
	PlayerPotions.potionUsed.connect(_on_potion_used);
	PlayerPotions.potionEffectFinished.connect(_on_potion_effect_finished);
	change_body_mesh_albedo_texture(bodyBaseColor)


# TODO: Utilizar este event para cambiar el color del cuerpo en vez del create timer que hay en el on_potion_used
func on_potion_drink_animation_finished() -> void:
	if currentPotion != PotionTypes.PotionType.None:
		change_body_mesh_albedo_based_on_potion_type(currentPotion)

func _on_potion_used(potionType: PotionTypes.PotionType) -> void:
	currentPotion = potionType
	await get_tree().create_timer(2.1).timeout
	change_body_mesh_albedo_based_on_potion_type(potionType)


func _on_player_selected_potion_changed(potionType: PotionTypes.PotionType):
	change_body_mesh_albedo_based_on_potion_type(potionType)
	
func change_body_mesh_albedo_based_on_potion_type(potionType: PotionTypes.PotionType) -> void:
	var texture = potionTypeToTextureLookUp.get(potionType)
	if texture:
		change_body_mesh_albedo_texture(texture)
	else:
		change_body_mesh_albedo_texture(bodyBaseColor)

func change_body_mesh_albedo_texture(texture: CompressedTexture2D) -> void:
	bodyMeshNode.get_active_material(0).set_texture(Decal.TEXTURE_ALBEDO, texture)

func _on_potion_effect_finished(_potionType: PotionTypes.PotionType) -> void:
	change_body_mesh_albedo_texture(bodyBaseColor)
	currentPotion = PotionTypes.PotionType.None

