class_name Arc extends Area3D

@onready var arcOn: Node3D = %ArcOn
@onready var arcOff: Node3D = %ArcOff


@onready var deactiovationTimer: Timer = $DeactivationTimer

var active = false;

var maintainActive := false;

signal active_changed(active: bool)

func _ready() -> void:
  deactiovationTimer.connect("timeout", _on_deactivation_timer_timeout)
  deactivate()

func activate() -> void:
  active = true
  arcOn.visible = true
  arcOff.visible = false
  active_changed.emit(true)
  deactiovationTimer.start()

func deactivate() -> void:
  
  if maintainActive:
    return;

  active = false
  arcOn.visible = false
  arcOff.visible = true
  active_changed.emit(false)

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
    activate()

func _on_deactivation_timer_timeout() -> void:
  deactivate()