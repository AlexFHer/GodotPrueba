extends Area3D

@onready var animation_tree: AnimationTree = $Mesh/AnimationTree

var opened = false

@export var openChestAudio: AudioStreamPlayer3D;
@export var collectableId := ""

func _ready() -> void:
	_restore_progress.call_deferred()

func _restore_progress() -> void:
	opened = CollectablesEmitterService.is_collected(self)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer") and not opened:
		if does_player_has_key():
			open_chest()
		else:
			GameLog.warn("Player attempted to open chest without key")

func open_chest():
	if opened:
		return

	if not CollectablesEmitterService.emitMithrilPickedUp(10, self):
		return
	opened = true
	openChestAudio.play()
	PlayerInventory.remove_key()

func does_player_has_key() -> bool:
	return PlayerInventory.keys > 0
