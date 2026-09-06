class_name MagicChest extends StaticBody3D

@onready var _forceField: Node3D = $MagicChestModel/Magic_Chest/ForceField
@onready var _forceFieldCollision: CollisionShape3D = $ForceFieldCollisionShape
@onready var _chest_open_audio: AudioStreamPlayer3D = $OpenAudioStreamPlayer

@export var numberOfMithrils := 10;
@export var collectableId := ""

var opened := false;
var isForceFieldActive := true;

func _ready() -> void:
	_restore_progress.call_deferred()

func _restore_progress() -> void:
	if CollectablesEmitterService.is_collected(self):
		opened = true
		deactivate_force_field()

func open_chest() -> void:
	opened = true;
	_chest_open_audio.play()

func deactivate_force_field() -> void:
	if not isForceFieldActive or not is_instance_valid(_forceField):
		return
	
	# Keep animation track targets alive when restoring an already opened chest.
	_forceField.hide()
	_forceFieldCollision.set_deferred("disabled", true)
	isForceFieldActive = false

func can_open() -> bool:
	return opened == false and isForceFieldActive == false

func add_number_of_mithrils() -> bool:
	return CollectablesEmitterService.emitMithrilPickedUp(numberOfMithrils, self)

func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer") and can_open():
		if add_number_of_mithrils():
			open_chest()
