extends Area3D

@export var bookPickupAudio: AudioStreamPlayer3D;
@export var collectableId := ""
var _collected := false

@onready var _model: Node3D = $Model;
@onready var _collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
  _restore_progress.call_deferred()

func _restore_progress() -> void:
  if CollectablesEmitterService.is_collected(self):
    _collected = true
    hide()
    queue_free()

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer") and not _collected:
    if not CollectablesEmitterService.emitBooksPickedUp(1, self):
      return
    _collected = true
    remove_collsion()
    hide_mesh()
    bookPickupAudio.play()
    await bookPickupAudio.finished
    queue_free()

func remove_collsion() -> void:
  _collision.set_deferred("disabled", true)

func hide_mesh() -> void:
  _model.visible = false
