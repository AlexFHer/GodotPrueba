class_name MagicChest extends StaticBody3D

@onready var _forceField: Node3D = $ForceFieldModel
@onready var _chest: Node3D = $MagicChestModel

@onready var _chest_animation_tree: AnimationTree = $MagicChestModel/MagicChestAnimationTree

@export var numberOfMithrils := 10;

var opened := false;
var isForceFieldActive := true;

func open_chest() -> void:
	opened = true;
	pass;

func deactivate_force_field() -> void:
	_forceField.queue_free()
	isForceFieldActive = false

func can_open() -> bool:
	return opened == false and isForceFieldActive == false

func add_number_of_mithrils() -> void:
	CollectablesEmitterService.emitMithrilPickedUp(numberOfMithrils)

func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer") and can_open():
		open_chest()
		add_number_of_mithrils();
