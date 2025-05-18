class_name FireTower extends Node3D

signal fire_activated

@onready var fire_tower: Node3D = $Fire_Tower_Model

var activated := false

signal active_changed(newActive: bool)

func _ready():
    deactivate_fire_tower()

func _on_area_entered(area: Area3D) -> void:
    if area.is_in_group("FireBall") and not activated:
        activate_fire_tower()
        
func activate_fire_tower() -> void:
    fire_tower.visible = true
    activated = true
    fire_activated.emit()

func deactivate_fire_tower() -> void:
    fire_tower.visible = false
    activated = false