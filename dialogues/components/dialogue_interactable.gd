@tool
class_name DialogueInteractable extends Area3D

const PLAYER_GROUP := &"MainPlayer"
const CONTROLLER_GROUP := &"dialogue_controller"
const DEFAULT_INTERACTION_RADIUS := 2.5

@export var dialogue_data: DialogueData:
	set(value):
		dialogue_data = value
		if Engine.is_editor_hint() and is_inside_tree():
			update_configuration_warnings()

@export_range(0.1, 100.0, 0.1, "or_greater") var interaction_radius := DEFAULT_INTERACTION_RADIUS:
	set(value):
		interaction_radius = maxf(value, 0.1)
		_apply_interaction_radius()

var _player: Node3D
var _controller: Node


func _ready() -> void:
	_apply_interaction_radius()
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return

	_unregister_candidate()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not Engine.is_editor_hint():
		return warnings

	if dialogue_data == null:
		warnings.append("Assign a DialogueData resource.")
	else:
		for validation_error in dialogue_data.get_validation_errors():
			warnings.append(validation_error)

	var collision_shape := get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		warnings.append("Add a CollisionShape3D child for the interaction radius.")
	elif collision_shape.shape == null:
		warnings.append("Assign a Shape3D to CollisionShape3D.")
	elif not collision_shape.shape is SphereShape3D:
		warnings.append("Use a SphereShape3D for a consistent interaction radius.")
	elif collision_shape.disabled:
		warnings.append("Enable CollisionShape3D so the player can enter the interaction radius.")

	if collision_layer != 0:
		warnings.append("DialogueInteractable must use collision layer 0.")
	if collision_mask != 1:
		warnings.append("DialogueInteractable must use collision mask 1 to detect MainPlayer.")

	return warnings


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	if is_instance_valid(_player):
		return

	_player = body
	_register_candidate()


func _on_body_exited(body: Node3D) -> void:
	if body != _player:
		return

	_unregister_candidate()


func _register_candidate() -> void:
	if not is_instance_valid(_player):
		return

	_controller = get_tree().get_first_node_in_group(CONTROLLER_GROUP)
	if not is_instance_valid(_controller):
		_log_warning("DialogueInteractable '%s' could not find a dialogue controller." % name)
		return
	if not _controller.has_method(&"register_candidate"):
		_log_error("Node '%s' in group '%s' cannot register dialogue candidates." % [_controller.name, CONTROLLER_GROUP])
		_controller = null
		return

	_controller.register_candidate(self, _player)


func _unregister_candidate() -> void:
	var player_to_unregister := _player
	_player = null

	if not is_instance_valid(_controller) and is_inside_tree():
		_controller = get_tree().get_first_node_in_group(CONTROLLER_GROUP)
	if is_instance_valid(_controller) and _controller.has_method(&"unregister_candidate"):
		if is_instance_valid(player_to_unregister):
			_controller.unregister_candidate(self, player_to_unregister)
		else:
			_controller.unregister_candidate(self)

	_controller = null


func _apply_interaction_radius() -> void:
	var collision_shape := get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		return

	var sphere := collision_shape.shape as SphereShape3D
	if sphere != null and not is_equal_approx(sphere.radius, interaction_radius):
		sphere.radius = interaction_radius


func _log_warning(message: String) -> void:
	var game_log := get_node_or_null(^"/root/GameLog")
	if game_log != null and game_log.has_method(&"warn"):
		game_log.call(&"warn", message)
	else:
		push_warning(message)


func _log_error(message: String) -> void:
	var game_log := get_node_or_null(^"/root/GameLog")
	if game_log != null and game_log.has_method(&"error"):
		game_log.call(&"error", message)
	else:
		push_error(message)
