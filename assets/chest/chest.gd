extends Area3D

@onready var animation_tree: AnimationTree = $Mesh/AnimationTree

var opened = false

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
      open_chest()

func open_chest():
    animation_tree.set("parameters/open_chest/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_player_enter_area(player: ) -> void:
  pass