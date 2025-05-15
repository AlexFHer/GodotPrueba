extends Node3D

@onready var fire_tower: Node3D = $Fire_Tower_Model

func _ready():
    pass
    fire_tower.visible = false

func _on_area_entered(area: Area3D) -> void:
    print("HIT");
    if area.is_in_group("FireBall"):
        fire_tower.visible = true
        print("encendido")
