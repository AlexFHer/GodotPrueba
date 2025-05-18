extends Area3D

@onready var animation_tree: AnimationTree = $Mesh/AnimationTree

var opened = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		if does_player_has_key():
			open_chest()
		else:
			print("Player does not have a key to open the chest")

func open_chest():
	opened = true
	CollectablesEmitterService.emitMithrilPickedUp(10)

func does_player_has_key() -> bool:
	return PlayerInventory.keys > 0
