extends Area3D

var opened = false

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
      if opened:
        return
      
      open_chest()

func open_chest():
    pass;

func _on_player_enter_area(player: ) -> void:
  pass