extends Node3D

@onready var fire_tower: Node3D = $Fire_Tower_Model

func _ready():
    pass
    $Fire_Tower_Model.visible = false

func _on_area_3d_body_entered(body:Node3D) -> void:
    print("hit"+body.name)
    if body.is_in_group("FireBall"):
      $Fire_Tower_Model.visible = true
      print("encendido")