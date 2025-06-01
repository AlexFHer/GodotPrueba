extends Enemy

const LEAVE_READY_STATE_TIME := 2.0
const ROTATION_SENSIVITY := 4.0
const DEFAULT_MITHRIL := 10

const MELEE_ATTACK_COLLISION_DURATION := 0.2
const DIE_DELAY_TIME := 2

enum State {
	Idle,
	Ready,
	Dead,
	Attack
}

@onready var _rig: Node3D = %Rig
@onready var _leave_ready_timer: Timer = %LeaveReadyTimer
@onready var death_particles: GPUParticles3D = %DeathParticles
@onready var attack_collider: CollisionShape3D = %MeleeAttackCollider

@export var number_of_mythril: int = DEFAULT_MITHRIL


var state := State.Idle

var isPlayerInRange := false
var isPlayerInAttackRange := false
var player: MainPlayer = null

func _ready() -> void:
	_set_state(State.Idle)
	disable_attack_collision()

func _process(delta: float) -> void:
	if state == State.Dead:
		return

	if state == State.Ready and isPlayerInRange:
		_look_at_player(delta)

func enable_attack_collision() -> void:
	attack_collider.disabled = false

func disable_attack_collision() -> void:
	attack_collider.disabled = true

func on_die_animation_finished() -> void:
	await get_tree().create_timer(DIE_DELAY_TIME).timeout
	_hide_mesh();
	if death_particles:
		death_particles.emitting = true
		death_particles.finished.connect(_on_death_particles_finished)

func get_hit() -> void:
	if state == State.Dead:
		return
	die()

func _set_state(new_state: State) -> void:
	if state == State.Dead:
		return
	if state == new_state:
		return
		
	state = new_state
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
		_leave_ready_timer.stop()

func _leave_ready_state() -> void:
	isPlayerInRange = false
	player = null
	_set_state(State.Idle)

func _on_leave_ready_timer_timeout() -> void:
	_leave_ready_state()

func die() -> void:
	CollectablesEmitterService.emitMithrilPickedUp(number_of_mythril)
	_set_state(State.Dead)

func _on_player_in_range_area_3d_body_exited(body:Node3D) -> void:
	if body is MainPlayer:
		_leave_ready_timer.start(LEAVE_READY_STATE_TIME)

func _on_attack_range_area_3d_body_entered(body:Node3D) -> void:
	if body is MainPlayer:
		_set_state(State.Attack)
		isPlayerInAttackRange = true

func _on_attack_range_area_3d_body_exited(body:Node3D) -> void:
	if body is MainPlayer:
		isPlayerInAttackRange = false
		
func _on_attack_animation_finished() -> void:
	if !isPlayerInAttackRange:
		_set_state(State.Ready)

func _on_attack_collision_area_3d_body_entered(body:Node3D) -> void:
	if body is MainPlayer:
		body.dealDamage()
		disable_attack_collision()

func _on_death_particles_finished() -> void:
	queue_free()

func _hide_mesh() -> void:
	_rig.visible = false
