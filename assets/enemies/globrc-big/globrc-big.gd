extends Enemy

const LEAVE_READY_STATE_TIME := 2.0
const ROTATION_SENSIVITY := 4.0
const DEFAULT_MITHRIL := 10

enum State {
	Idle,
	Ready,
	Dead
}

@onready var _rig: Node3D = %Rig
@onready var leave_ready_timer: Timer = %LeaveReadyTimer

@export var number_of_mythril: int = DEFAULT_MITHRIL

var state := State.Idle

var isPlayerInRange := false
var player: MainPlayer = null

func _ready() -> void:
	_set_state(State.Idle)

func _set_state(new_state: State) -> void:
	if state == State.Dead:
		return
	if state == new_state:
		return
		
	state = new_state

func _process(delta: float) -> void:
	if state == State.Dead:
		return

	if state == State.Ready and isPlayerInRange:
		_look_at_player(delta)

func _look_at_player(delta: float) -> void:
	if player == null or isPlayerInRange == false:
		return
	var to_player = player.global_position - _rig.global_position
	to_player.y = 0
	var angle = atan2(to_player.x, to_player.z)
	_rig.global_rotation.y = lerp_angle(_rig.global_rotation.y, angle, ROTATION_SENSIVITY * delta)

func _on_player_in_range_area_3d_body_entered(body:Node3D) -> void:
	if body is MainPlayer:
		isPlayerInRange = true
		player = body
		_set_state(State.Ready)
		leave_ready_timer.stop()

func _on_player_in_range_area_3d_body_exited(body:Node3D) -> void:
	if body is MainPlayer:
		leave_ready_timer.start(LEAVE_READY_STATE_TIME)

func _leave_ready_state() -> void:
	isPlayerInRange = false
	player = null
	_set_state(State.Idle)

func _on_leave_ready_timer_timeout() -> void:
	_leave_ready_state()

func die() -> void:
	CollectablesEmitterService.emitMithrilPickedUp(number_of_mythril)
	_set_state(State.Dead)
