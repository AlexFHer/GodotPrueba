extends Node3D

@export var magic_chest: MagicChest;
@export var arc_puzzle: AllArcsActivePuzzle;

func _ready() -> void:
  arc_puzzle.all_arcs_active.connect(_on_all_arcs_active)

func _on_all_arcs_active() -> void:
  magic_chest.deactivate_force_field()
