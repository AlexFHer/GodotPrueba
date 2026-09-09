extends Node

var _source: Area3D
var _destination: Area3D
var _player: MainPlayer
var _previous_camera: Camera3D
var _initial_transform: Transform3D
var _initial_visible: bool
var _initial_direction: Vector3
var _animation: Tween
var _finished: bool = false

func start(source: Area3D, destination: Area3D, player: MainPlayer) -> void:
	if not player.begin_teleport(self):
		queue_free()
		return
	_source = source
	_destination = destination
	_player = player
	_initial_transform = player.global_transform
	_initial_visible = player.visible
	_initial_direction = player.lastMovementDirection
	_previous_camera = player.get_viewport().get_camera_3d()
	source.block_arrival(player)
	destination.block_arrival(player)
	for participant in [source, destination, player]:
		participant.tree_exiting.connect(_abort, CONNECT_ONE_SHOT)
	source.camera.make_current()
	player.set_teleport_pose(&"Potma_Fall")
	_animation = create_tween()
	_animation.tween_property(player, "global_position", source.entry_point.global_position, 0.25).set_trans(Tween.TRANS_SINE)
	_animation.tween_property(player, "global_position", source.inside_point.global_position, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.tween_callback(player.hide)
	_animation.tween_interval(source.source_hold)
	_animation.tween_callback(_switch_to_destination)
	_animation.tween_interval(destination.destination_hold)
	_animation.tween_callback(_launch)
	_animation.tween_method(_jump, 0.0, 1.0, destination.jump_duration)
	_animation.tween_callback(func() -> void: _player.set_teleport_pose(&"Potma_Idle"))
	_animation.tween_interval(destination.landing_hold)
	_animation.tween_callback(_complete)

func _switch_to_destination() -> void:
	_player.global_position = _destination.inside_point.global_position
	_player.reset_physics_interpolation()
	_destination.camera.make_current()

func _launch() -> void:
	_player.visible = _initial_visible
	_player.face_teleport_exit(_destination.exit_point.global_position - _destination.inside_point.global_position)
	_player.set_teleport_pose(&"Potma_Jump")
	_player.potmaSounds.jumpSoundAudioStream.play()

func _jump(progress: float) -> void:
	var start_position: Vector3 = _destination.inside_point.global_position
	var end_position: Vector3 = _destination.exit_point.global_position
	_player.global_position = start_position.lerp(end_position, progress) + Vector3.UP * (4.0 * _destination.jump_height * progress * (1.0 - progress))

func _complete() -> void:
	_finish(false)

func _abort() -> void:
	_finish(true)

func _finish(aborted: bool) -> void:
	if _finished:
		return
	_finished = true
	if _animation != null:
		_animation.kill()
	if is_instance_valid(_player) and _player.is_inside_tree():
		if aborted:
			_player.global_transform = _initial_transform
			_player.face_teleport_exit(_initial_direction)
		_player.visible = _initial_visible
		_player.end_teleport(self)
		if is_instance_valid(_previous_camera) and _previous_camera.is_inside_tree():
			_previous_camera.make_current()
		_release_blocks(_player)
	queue_free()

func _release_blocks(player: MainPlayer) -> void:
	if not is_instance_valid(player):
		return
	for well in [_source, _destination]:
		if is_instance_valid(well) and well.is_inside_tree():
			well.release_if_outside(player)

func _exit_tree() -> void:
	if not _finished:
		_finish(true)
