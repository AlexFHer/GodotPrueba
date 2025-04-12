extends Area3D

@onready var animation_tree: AnimationTree = $Mesh/AnimationTree

var opened = false

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
      open_chest()

func open_chest():
    opened = true

func _on_player_enter_area(player: ) -> void:
  pass