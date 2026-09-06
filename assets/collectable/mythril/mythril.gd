extends Area3D

@export var value = 1
@export var collectableId := ""
var _collected := false
@export var coinPickupAudio: AudioStreamPlayer3D;
@export var mesh: Node3D;
@export var collision: CollisionShape3D;
@export var numberPackedScene: PackedScene;
@export var mythrillParticles: GPUParticles3D

func _ready() -> void:
	_restore_progress.call_deferred()

func _restore_progress() -> void:
	if CollectablesEmitterService.is_collected(self):
		_collected = true
		hide()
		queue_free()

func _on_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer") and not _collected:
		if not CollectablesEmitterService.emitMithrilPickedUp(value, self):
			return
		_collected = true
		hide_mesh();
		disable_collision()
		instantiate_number()
		coinPickupAudio.play()
		mythrillParticles.emitting = true
		await coinPickupAudio.finished
		queue_free()

func hide_mesh():
	mesh.visible = false

func disable_collision():
	if collision == null:
		return
	collision.set_deferred("disabled", true)

func instantiate_number():
	if numberPackedScene == null:
		return
	var number = numberPackedScene.instantiate()
	number.position = Vector3(0, 0.5, 0)
	add_child(number)
