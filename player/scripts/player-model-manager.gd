extends Node3D

var speedPotionMesh: PackedScene = load("res://assets/potions/speed-potion/mesh/SpeedPotion.glb")

@onready var potionPlaceHolder: MeshInstance3D = $Armature/Potma/Armature_Potma/Skeleton3D/Poti_placeHolder

func _ready() -> void:
	PlayerPotions.selectedPotionChanged.connect(_on_player_selected_potion_changed);


func _on_player_selected_potion_changed(potionType: PotionTypes.PotionType):
	if potionType == PotionTypes.PotionType.Speed:
		pass
		
