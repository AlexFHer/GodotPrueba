class_name TeleportWell extends Area3D

const TRAVEL_SCRIPT = preload("res://assets/teleports/teleport_travel.gd")

@export var destination: TeleportWell
@export_group("Sequence")
@export_range(0.0, 6.0) var source_hold: float = 2.0
@export_range(0.0, 3.0) var destination_hold: float = 0.35
@export_range(0.2, 3.0) var jump_duration: float = 1.0
@export_range(0.2, 5.0) var jump_height: float = 2.0
@export_range(0.0, 3.0) var landing_hold: float = 0.3

@onready var camera: Camera3D = $TeleportCamera
@onready var entry_point: Marker3D = $EntryPoint
@onready var inside_point: Marker3D = $InsidePoint
@onready var exit_point: Marker3D = $ExitPoint

var _blocked_players: Array[int] = []

func _ready() -> void:
	camera.look_at($CameraFocus.global_position, Vector3.UP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is MainPlayer:
		_try_enter.call_deferred(body)

func _try_enter(player: MainPlayer) -> void:
	if not is_instance_valid(player) or not overlaps_body(player):
		return
	if player.is_teleporting() or _blocked_players.has(player.get_instance_id()):
		return
	if not is_instance_valid(destination) or destination == self or not destination.is_inside_tree():
		push_warning("Teleport needs a different destination in the same level: %s" % name)
		return
	var travel = TRAVEL_SCRIPT.new()
	get_tree().current_scene.add_child(travel)
	travel.start(self, destination, player)

func block_arrival(player: MainPlayer) -> void:
	var id := player.get_instance_id()
	if not _blocked_players.has(id):
		_blocked_players.append(id)

func play_water_entry() -> void:
	$well_Imported/Plane.play_entry_splash()

func _on_body_exited(body: Node3D) -> void:
	if body is MainPlayer and not body.is_teleporting():
		_blocked_players.erase(body.get_instance_id())

func release_if_outside(player: MainPlayer) -> void:
	# Wait for restored collision layers to appear in the physics overlap list.
	get_tree().create_timer(0.1, false, true).timeout.connect(
		_clear_arrival_block.bind(player), CONNECT_ONE_SHOT)

func _clear_arrival_block(player: MainPlayer) -> void:
	if not is_instance_valid(player) or player.is_teleporting():
		return
	if not overlaps_body(player):
		_blocked_players.erase(player.get_instance_id())
