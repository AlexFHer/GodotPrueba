class_name SecretTower extends Node3D

@onready var secret_tower: Node3D = $Model

var activated := false

func activate_secret_tower() -> void:
  secret_tower.visible = true
  activated = true
  print("Secret tower activated")

