class_name Baby extends Area3D

@export var collectableId := ""
var _collected := false

func _ready() -> void:
	_restore_progress.call_deferred()

func _restore_progress() -> void:
	if CollectablesEmitterService.is_collected(self):
		_collected = true
		hide()
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer") and not _collected:
		if not CollectablesEmitterService.emitBabyPickedUp(1, self):
			return
		_collected = true
		hide()
		queue_free()
