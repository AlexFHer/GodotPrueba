extends Enemy

const LEAVE_READY_STATE_TIME := 2.0
const ROTATION_SENSIVITY := 4.0
const DEFAULT_MITHRIL := 10

const MELEE_ATTACK_COLLISION_DURATION := 0.2

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
@onready var body_collider: CollisionShape3D = $CollisionShape3D

@export var number_of_mythril: int = DEFAULT_MITHRIL
@export var collectableId := ""
@export_range(0.0, 10.0, 0.1) var attack_cooldown_min := 1.0
@export_range(0.0, 10.0, 0.1) var attack_cooldown_max := 1.6
@export_range(0.0, 2.0, 0.05) var attack_windup_time := 0.45
@export_range(1.0, 90.0, 1.0) var attack_facing_angle_degrees := 28.0
@export_range(0.0, 5.0, 0.1) var death_hide_delay := 1.25

var shockwave_scene: PackedScene = preload("res://assets/enemies/globrc-big/assets/shockwave/globrc_shockwave.tscn")
@onready var shockwave_spawn_point: Node3D = %ShockwaveSpawnPoint
@onready var dust_particles: GPUParticles3D = %DustBurstParticles

var state := State.Idle
var _attack_cooldown_remaining := 0.0
var _attack_windup_remaining := 0.0
var _death_finished := false

var isPlayerInRange := false
var isPlayerInAttackRange := false
var player: MainPlayer = null

func _ready() -> void:
	_set_state(State.Idle)
	disable_attack_collision()

func _process(delta: float) -> void:
	if state == State.Dead:
		return

	_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)
	if state == State.Ready and isPlayerInRange:
		_look_at_player(delta)
	if state == State.Ready:
		_update_attack_windup(delta)

func enable_attack_collision() -> void:
	if state == State.Dead:
		return
	attack_collider.disabled = false

func disable_attack_collision() -> void:
	attack_collider.disabled = true

func _spawn_shockwave() -> void:
	var shockwave_instance: Node3D = shockwave_scene.instantiate()
	get_tree().current_scene.add_child(shockwave_instance)
	shockwave_instance.global_position = shockwave_spawn_point.global_position
	print("SPAWN SHOCKWAVE EN: ", shockwave_spawn_point.global_position)
	_spawn_dust_particles()

func _spawn_dust_particles() -> void:
	if state == State.Dead:
		return
	dust_particles.emitting = true

func on_die_animation_finished() -> void:
	_finish_death()

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
	if to_player.length_squared() <= 0.001:
		return
	var angle = atan2(to_player.x, to_player.z)
	_rig.global_rotation.y = lerp_angle(_rig.global_rotation.y, angle, ROTATION_SENSIVITY * delta)

func _update_attack_windup(delta: float) -> void:
	if not isPlayerInAttackRange or _attack_cooldown_remaining > 0.0 or not _is_facing_player():
		_attack_windup_remaining = 0.0
		return
	_attack_windup_remaining += delta
	if _attack_windup_remaining >= attack_windup_time:
		_attack_windup_remaining = 0.0
		_set_state(State.Attack)

func _is_facing_player() -> bool:
	if player == null:
		return false
	var to_player := player.global_position - _rig.global_position
	to_player.y = 0.0
	if to_player.length_squared() <= 0.001:
		return true
	var target_angle := atan2(to_player.x, to_player.z)
	return absf(angle_difference(_rig.global_rotation.y, target_angle)) <= deg_to_rad(attack_facing_angle_degrees)

func _on_player_in_range_area_3d_body_entered(body:Node3D) -> void:
	if body is MainPlayer:
		isPlayerInRange = true
		player = body
		_set_state(State.Ready)
		_leave_ready_timer.stop()

func _leave_ready_state() -> void:
	isPlayerInRange = false
	isPlayerInAttackRange = false
	_attack_windup_remaining = 0.0
	player = null
	_set_state(State.Idle)

func _on_leave_ready_timer_timeout() -> void:
	_leave_ready_state()

func die() -> void:
	CollectablesEmitterService.emitMithrilPickedUp(number_of_mythril, self)
	_set_state(State.Dead)
	velocity = Vector3.ZERO
	isPlayerInRange = false
	isPlayerInAttackRange = false
	disable_attack_collision()
	body_collider.set_deferred("disabled", true)
	await get_tree().create_timer(death_hide_delay, false).timeout
	_finish_death()

func _on_player_in_range_area_3d_body_exited(body:Node3D) -> void:
	if body is MainPlayer:
		_leave_ready_timer.start(LEAVE_READY_STATE_TIME)

func _on_attack_range_area_3d_body_entered(body:Node3D) -> void:
	if body is MainPlayer:
		isPlayerInAttackRange = true
		_attack_windup_remaining = 0.0

func _on_attack_range_area_3d_body_exited(body:Node3D) -> void:
	if body is MainPlayer:
		isPlayerInAttackRange = false
		_attack_windup_remaining = 0.0
		
func _on_attack_animation_finished() -> void:
	if state == State.Dead:
		return
	var minimum := maxf(0.0, attack_cooldown_min)
	_attack_cooldown_remaining = randf_range(minimum, maxf(minimum, attack_cooldown_max))
	_set_state(State.Ready if isPlayerInRange else State.Idle)

func _on_attack_collision_area_3d_body_entered(body:Node3D) -> void:
	if body is MainPlayer:
		if body.has_method("take_damage"):
			body.take_damage()
		disable_attack_collision()

func _on_death_particles_finished() -> void:
	queue_free()

func _hide_mesh() -> void:
	_rig.visible = false

func _finish_death() -> void:
	if _death_finished:
		return
	_death_finished = true
	_hide_mesh()
	if death_particles:
		if not death_particles.finished.is_connected(_on_death_particles_finished):
			death_particles.finished.connect(_on_death_particles_finished)
		death_particles.restart()
		death_particles.emitting = true
	else:
		queue_free()
