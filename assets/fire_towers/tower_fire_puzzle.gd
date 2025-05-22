class_name FireTower extends Node3D

signal fire_state(newActive: bool)

@export var towerFireAudio: AudioStreamPlayer3D;

@onready var fire_tower: Node3D = $Fire_Tower_Model

var activated := false

func _ready():
		deactivate_fire_tower()

func _on_area_entered(area: Area3D) -> void:
		if area.is_in_group("FireBall") and not activated:
				activate_fire_tower()
				
func activate_fire_tower() -> void:
		towerFireAudio.play()
		fire_tower.visible = true
		activated = true
		fire_state.emit()

func deactivate_fire_tower() -> void:
		fire_tower.visible = false
		activated = false