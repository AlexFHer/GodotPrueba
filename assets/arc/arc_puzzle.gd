class_name AllArcsActivePuzzle extends Node3D

@export var arcs: Array[Arc] = []

signal all_arcs_active()

func _ready() -> void:
	for arc in arcs:
		if arc != null:
			arc.active_changed.connect(_on_arc_active_changed)
		else:
			print_debug(name + "has null arcs");

func areAllArcsActive() -> bool:
	for arc in arcs:
		if not arc.active:
			return false
	return true

func _on_arc_active_changed(_active: bool) -> void:
	if areAllArcsActive():
		all_arcs_active.emit()
		makeAllMaintainActive()

func makeAllMaintainActive() -> void:
	for arc in arcs:
		arc.maintainActive = true
