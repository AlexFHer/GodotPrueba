extends Area3D

var target: Node3D;
var elapsed = 0.0;

var value = 1;

@export var collectableId := ""
var _collected := false

func _ready() -> void:
	_restore_progress.call_deferred()

func _restore_progress() -> void:
	if CollectablesEmitterService.is_collected(self):
		_collected = true
		hide()
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target != null:
		checkTarget(delta);

func checkTarget(delta: float) -> void:
	if target == null:
		pass

	position = lerp(position, target.position, 0.3)
	elapsed += delta

func _on_object_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer") and not _collected:
		if not CollectablesEmitterService.emitMithrilPickedUp(value, self):
			return
		_collected = true
		queue_free();


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		target = body;
