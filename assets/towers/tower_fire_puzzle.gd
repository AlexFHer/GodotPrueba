extends Node3D

signal fire_activated 

@onready var fire_tower: Node3D = $Fire_Tower_Model
var activated := false

func _ready():
    fire_tower.visible = false

func _on_area_entered(area: Area3D) -> void:
    if area.is_in_group("FireBall") and not activated:
        print("HIT")
        fire_tower.visible = true
        activated = true
        fire_activated.emit()
        
