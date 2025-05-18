extends StaticBody3D

@onready var doorCollider: CollisionShape3D = $DoorCollider

var opened := false;

func open_door() -> void:
  opened = true;
  doorCollider.disabled = true;