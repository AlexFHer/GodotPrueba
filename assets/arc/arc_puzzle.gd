extends Node

@export var arcs: Array[Arc] = []

signal all_arcs_active()

func _ready() -> void:
  for arc in arcs:
    arc.active_changed.connect(_on_arc_active_changed)

func areAllArcsActive() -> bool:
  for arc in arcs:
    if not arc.active:
      return false
  return true

func _on_arc_active_changed(_active: bool) -> void:
  if areAllArcsActive():
    all_arcs_active.emit()