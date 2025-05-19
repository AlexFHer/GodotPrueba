extends Area3D

@onready var animation_tree: AnimationTree = $Mesh/AnimationTree

var opened = false

@export var openChestAudio: AudioStreamPlayer3D;

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		if does_player_has_key():
			open_chest()
			openChestAudio.play()
		else:
			print("Player does not have a key to open the chest")

func open_chest():
	if opened:
		return

	opened = true
	CollectablesEmitterService.emitMithrilPickedUp(10)
	PlayerInventory.remove_key()

func does_player_has_key() -> bool:
	return PlayerInventory.keys > 0
