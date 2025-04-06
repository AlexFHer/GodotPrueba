class_name Arc extends Area3D

@onready var activatedMesh: MeshInstance3D = $Activated
@onready var deactiovationTimer: Timer = $DeactivationTimer

var active = false;

signal active_changed(active: bool)

func _ready() -> void:
  deactiovationTimer.connect("timeout", _on_deactivation_timer_timeout)
  deactivate()

func activate() -> void:
  active = true
  activatedMesh.visible = true
  active_changed.emit(true)
  deactiovationTimer.start()

func deactivate() -> void:
  active = false
  activatedMesh.visible = false
  active_changed.emit(false)

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
    activate()

func _on_deactivation_timer_timeout() -> void:
  deactivate()