class_name DialogueController
extends Node

signal dialogue_started(data: DialogueData)
signal dialogue_finished(data: DialogueData)

const INTERACT_ACTION: StringName = &"interact"
const START_ACTION: StringName = &"start"
const DISTANCE_TIE_EPSILON := 0.0001

enum DialogueState {
	IDLE,
	ACTIVE,
	CLOSING,
}

@onready var _ui: DialogueUI = %DialogueUI
@onready var _line_audio_player: AudioStreamPlayer = %LineAudioPlayer

var _state := DialogueState.IDLE
var _candidates: Dictionary = {}
var _selected_interactable: DialogueInteractable
var _active_interactable: DialogueInteractable
var _active_data: DialogueData
var _active_lines: Array[DialogueLine] = []
var _line_index := -1

var _close_generation := 0
var _close_finish_queued := false
var _waiting_for_interact_release := false
var _closing_uses_joypad := false
var _closing_joypad_device := -1

var _last_input_was_joypad := false
var _last_joypad_device := -1
var _last_interact_was_joypad := false
var _last_interact_joypad_device := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_action_badge()
	_refresh_selected_candidate()


func _process(_delta: float) -> void:
	if _state == DialogueState.IDLE:
		if get_tree().paused:
			_selected_interactable = null
			_ui.hide_prompt()
			return
		_refresh_selected_candidate()
	elif _state == DialogueState.CLOSING and _waiting_for_interact_release:
		# Focus loss and some device drivers can drop the release event. Polling is a
		# fallback only; the normal path still consumes the release in _input().
		if not InputMap.has_action(INTERACT_ACTION) or not Input.is_action_pressed(INTERACT_ACTION):
			_on_interact_released()


func _input(event: InputEvent) -> void:
	_track_last_input_device(event)

	if _state != DialogueState.IDLE and _event_matches_action(event, START_ACTION):
		get_viewport().set_input_as_handled()
		return

	if _state == DialogueState.CLOSING:
		if _event_matches_action(event, INTERACT_ACTION):
			get_viewport().set_input_as_handled()
			if event.is_action_released(INTERACT_ACTION) and not Input.is_action_pressed(INTERACT_ACTION):
				_on_interact_released()
		return

	if _is_key_echo(event) and event.is_action_pressed(INTERACT_ACTION, true):
		if _state == DialogueState.ACTIVE:
			get_viewport().set_input_as_handled()
		elif _state == DialogueState.IDLE and not get_tree().paused:
			_refresh_selected_candidate()
			if _selected_interactable != null:
				get_viewport().set_input_as_handled()
		return

	if not _is_action_press(event, INTERACT_ACTION):
		return

	_last_interact_was_joypad = event is InputEventJoypadButton or event is InputEventJoypadMotion
	_last_interact_joypad_device = event.device if _last_interact_was_joypad else -1

	if _state == DialogueState.ACTIVE:
		get_viewport().set_input_as_handled()
		advance_dialogue()
		return

	if get_tree().paused:
		_selected_interactable = null
		_ui.hide_prompt()
		return

	_refresh_selected_candidate()
	if _selected_interactable == null:
		return

	get_viewport().set_input_as_handled()
	start_dialogue(_selected_interactable)


func _exit_tree() -> void:
	_close_generation += 1
	_stop_line_audio()
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)


func register_candidate(interactable: DialogueInteractable, player: Node3D) -> void:
	if not is_instance_valid(interactable) or not is_instance_valid(player):
		return

	var data := interactable.dialogue_data
	if data == null:
		_log_warning("Dialogue candidate '%s' has no DialogueData and was rejected." % interactable.name)
		return

	for validation_error in data.get_validation_errors():
		_log_warning("Dialogue candidate '%s': %s" % [interactable.name, validation_error])

	if _get_valid_lines(data).is_empty():
		return

	var instance_id := interactable.get_instance_id()
	_candidates[instance_id] = {
		"interactable": interactable,
		"player": player,
	}
	if _state == DialogueState.IDLE:
		_refresh_selected_candidate()


func unregister_candidate(interactable: DialogueInteractable, player: Node3D = null) -> void:
	if interactable == null:
		return

	var instance_id := interactable.get_instance_id()
	if not _candidates.has(instance_id):
		return

	if player != null:
		var entry: Dictionary = _candidates[instance_id]
		var registered_player: Variant = entry.get("player")
		if registered_player != player:
			return

	_candidates.erase(instance_id)
	if _state == DialogueState.IDLE:
		_refresh_selected_candidate()


func start_dialogue(interactable: DialogueInteractable = null) -> bool:
	var player := get_tree().get_first_node_in_group(&"MainPlayer") as MainPlayer
	if player != null and player.is_teleporting():
		_ui.hide_prompt()
		return false
	if _state != DialogueState.IDLE or get_tree().paused:
		_ui.hide_prompt()
		return false

	var target := interactable
	if target == null:
		_refresh_selected_candidate()
		target = _selected_interactable
	if not is_instance_valid(target):
		return false

	var data := target.dialogue_data
	var valid_lines := _get_valid_lines(data)
	if valid_lines.is_empty():
		_log_warning("Dialogue '%s' cannot start because its data has no valid lines." % target.name)
		unregister_candidate(target)
		return false

	_active_interactable = target
	_active_data = data
	_active_lines = valid_lines
	_line_index = 0
	_state = DialogueState.ACTIVE
	_selected_interactable = null
	_ui.hide_prompt()

	_ui.show_dialogue()
	_present_line(_active_lines[_line_index])
	dialogue_started.emit(_active_data)
	return true


func advance_dialogue() -> void:
	if _state != DialogueState.ACTIVE:
		return

	if _ui.is_revealing_text():
		_ui.finish_typewriter()
		return

	_line_index += 1
	if _line_index >= _active_lines.size():
		close_dialogue()
		return

	_present_line(_active_lines[_line_index])


func close_dialogue() -> void:
	if _state != DialogueState.ACTIVE:
		return

	_state = DialogueState.CLOSING
	_close_generation += 1
	_close_finish_queued = false
	_stop_line_audio()
	_ui.hide_dialogue()
	_ui.hide_prompt()

	_closing_uses_joypad = _last_interact_was_joypad
	_closing_joypad_device = _last_interact_joypad_device
	_waiting_for_interact_release = InputMap.has_action(INTERACT_ACTION) and Input.is_action_pressed(INTERACT_ACTION)

	var finished_data := _active_data
	dialogue_finished.emit(finished_data)

	# The action is intentionally shared with gameplay. Keep dialogue in a closing
	# state until the final press is released so polling-based gameplay input can
	# ignore that press without freezing the world.
	if not _waiting_for_interact_release:
		_queue_close_finish()


func is_consuming_gameplay_input() -> bool:
	return _state != DialogueState.IDLE


func _present_line(line: DialogueLine) -> void:
	_stop_line_audio()
	_ui.show_line(line)
	if line.voice_stream == null:
		return

	_line_audio_player.stream = line.voice_stream
	_line_audio_player.play()


func _stop_line_audio() -> void:
	if not is_instance_valid(_line_audio_player):
		return
	_line_audio_player.stop()
	_line_audio_player.stream = null


func _refresh_selected_candidate() -> void:
	if get_tree().paused:
		_selected_interactable = null
		_ui.hide_prompt()
		return

	var best_interactable: DialogueInteractable
	var best_distance_squared := INF
	var best_instance_id := 0
	var stale_ids: Array[int] = []

	for candidate_id_variant in _candidates:
		var candidate_id := int(candidate_id_variant)
		var entry: Dictionary = _candidates[candidate_id]
		var interactable_value: Variant = entry.get("interactable")
		var player_value: Variant = entry.get("player")
		if not is_instance_valid(interactable_value) or not is_instance_valid(player_value):
			_log_warning("Dialogue candidate %d referenced a freed interactable or player and was removed." % candidate_id)
			stale_ids.append(candidate_id)
			continue

		var interactable := interactable_value as DialogueInteractable
		var player := player_value as Node3D
		if player is MainPlayer and player.is_teleporting():
			continue
		if interactable == null or player == null:
			_log_warning("Dialogue candidate %d contained incompatible nodes and was removed." % candidate_id)
			stale_ids.append(candidate_id)
			continue

		var distance_squared := player.global_position.distance_squared_to(interactable.global_position)
		var is_better_distance := distance_squared < best_distance_squared - DISTANCE_TIE_EPSILON
		var is_stable_tie := absf(distance_squared - best_distance_squared) <= DISTANCE_TIE_EPSILON
		if is_better_distance or (is_stable_tie and (best_interactable == null or candidate_id < best_instance_id)):
			best_interactable = interactable
			best_distance_squared = distance_squared
			best_instance_id = candidate_id

	for stale_id in stale_ids:
		_candidates.erase(stale_id)

	if _selected_interactable == best_interactable:
		return

	_selected_interactable = best_interactable
	if _selected_interactable == null:
		_ui.hide_prompt()
	else:
		_ui.show_prompt()


func _get_valid_lines(data: DialogueData) -> Array[DialogueLine]:
	var valid_lines: Array[DialogueLine] = []
	if data == null:
		return valid_lines

	for line in data.lines:
		if line == null or line.text.strip_edges().is_empty():
			continue
		valid_lines.append(line)
	return valid_lines


func _on_interact_released() -> void:
	if not _waiting_for_interact_release:
		return
	_waiting_for_interact_release = false
	_queue_close_finish()


func _queue_close_finish() -> void:
	if _close_finish_queued or _state != DialogueState.CLOSING:
		return
	_close_finish_queued = true
	var generation := _close_generation
	var tree := get_tree()
	await tree.process_frame
	if not is_inside_tree() or generation != _close_generation or _state != DialogueState.CLOSING:
		return

	_state = DialogueState.IDLE
	_close_finish_queued = false
	_waiting_for_interact_release = false
	_closing_uses_joypad = false
	_closing_joypad_device = -1
	_active_interactable = null
	_active_data = null
	_active_lines.clear()
	_line_index = -1
	_refresh_selected_candidate()


func _track_last_input_device(event: InputEvent) -> void:
	var changed := false
	if event is InputEventJoypadButton:
		changed = not _last_input_was_joypad or _last_joypad_device != event.device
		_last_input_was_joypad = true
		_last_joypad_device = event.device
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= 0.35:
		changed = not _last_input_was_joypad or _last_joypad_device != event.device
		_last_input_was_joypad = true
		_last_joypad_device = event.device
	elif event is InputEventKey or event is InputEventMouseButton:
		changed = _last_input_was_joypad
		_last_input_was_joypad = false

	if changed:
		_update_action_badge()


func _update_action_badge() -> void:
	if not is_instance_valid(_ui):
		return
	_ui.set_action_badge(_get_action_badge())


func _get_action_badge() -> String:
	if not _last_input_was_joypad:
		return _get_keyboard_action_badge()

	var device := _get_valid_joypad_device(_last_joypad_device)
	if device < 0:
		return "A/X"

	var device_name := Input.get_joy_name(device).to_lower()
	var device_info := Input.get_joy_info(device)
	var vendor_id := int(device_info.get("vendor_id", 0))
	if vendor_id == 0x054C or _contains_any(device_name, ["sony", "playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5"]):
		return "X"
	if vendor_id == 0x045E or _contains_any(device_name, ["microsoft", "xbox", "xinput"]):
		return "A"
	return "A/X"


func _get_keyboard_action_badge() -> String:
	if not InputMap.has_action(INTERACT_ACTION):
		return "?"

	for mapped_event in InputMap.action_get_events(INTERACT_ACTION):
		var key_event := mapped_event as InputEventKey
		if key_event == null:
			continue
		if key_event.physical_keycode != 0:
			return OS.get_keycode_string(key_event.physical_keycode)
		if key_event.keycode != 0:
			return OS.get_keycode_string(key_event.keycode)
		if key_event.unicode != 0:
			return String.chr(key_event.unicode).to_upper()
	return "?"


func _get_valid_joypad_device(preferred_device: int) -> int:
	var connected_devices := Input.get_connected_joypads()
	if connected_devices.has(preferred_device):
		return preferred_device
	if connected_devices.is_empty():
		return -1
	return connected_devices[0]


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and _state == DialogueState.CLOSING and _waiting_for_interact_release:
		if _closing_uses_joypad and _closing_joypad_device == device:
			_waiting_for_interact_release = false
			_queue_close_finish()

	if not connected and _last_joypad_device == device:
		var fallback_device := _get_valid_joypad_device(-1)
		_last_joypad_device = fallback_device
		_last_input_was_joypad = fallback_device >= 0
	elif connected and _last_input_was_joypad and _last_joypad_device < 0:
		_last_joypad_device = device

	_update_action_badge()


func _is_action_press(event: InputEvent, action: StringName) -> bool:
	if not event.is_action_pressed(action, true):
		return false
	return not _is_key_echo(event)


func _is_key_echo(event: InputEvent) -> bool:
	return event is InputEventKey and event.echo


func _event_matches_action(event: InputEvent, action: StringName) -> bool:
	return event.is_action_pressed(action, true) or event.is_action_released(action)


func _contains_any(value: String, needles: Array[String]) -> bool:
	for needle in needles:
		if value.contains(needle):
			return true
	return false


func _log_warning(message: String) -> void:
	var game_log := get_node_or_null(^"/root/GameLog")
	if game_log != null and game_log.has_method(&"warn"):
		game_log.call(&"warn", message)
	else:
		push_warning(message)
