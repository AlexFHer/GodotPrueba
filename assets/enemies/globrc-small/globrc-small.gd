class_name GlobrcSmall extends Enemy

@onready var _rig: Node3D = $Rig
@onready var _animation_tree: AnimationTree = $Rig/AnimationTree
@onready var player_out_of_bounds_timer: Timer = $Rig/PlayerSearchArea/PlayerOutOfBoundsTimer
@onready var weapon_hit_collision_shape: CollisionShape3D = $Rig/WeaponHitArea/WeaponHitCollision
@onready var can_attack_timer: Timer = $canAttackTimer
@onready var death_particles: GPUParticles3D = %DeathParticles
@onready var body_collider: CollisionShape3D = $"Globrc collider"

@export var patrolPoints: Array[PatrolPoint] = [];

@export var speed: float = 250.0
@export var attackDamage: int = 1
@export_range(0.0, 2.0, 0.05) var attack_windup_time := 0.35
@export_range(1.0, 90.0, 1.0) var attack_facing_angle_degrees := 32.0
@export_range(0.0, 20.0, 0.1) var follow_turn_speed := 8.0
@export_range(0.0, 20.0, 0.1) var attack_turn_speed := 12.0
@export_range(0.0, 5.0, 0.1) var death_hide_delay := 0.85

var currentPatrolPoint: PatrolPoint = null;

var targetToFollow: Node3D = null

var isEnemyInRange  := false
var canAttack := true;
var _attack_windup_remaining := 0.0
var _death_finished := false

enum EnemyState {
	IDLE,
	PATROLLING,
	FOLLOWING,
	ATTACKING,
	DEAD
}
var enemyState: EnemyState = EnemyState.PATROLLING

func _ready():
	if not player_out_of_bounds_timer.timeout.is_connected(_on_player_out_of_bounds_timer_timeout):
		player_out_of_bounds_timer.timeout.connect(_on_player_out_of_bounds_timer_timeout)
	if not can_attack_timer.timeout.is_connected(_on_can_attack_timer_timeout):
		can_attack_timer.timeout.connect(_on_can_attack_timer_timeout)
	weapon_hit_collision_shape.disabled = true
	if patrolPoints.size() == 0:
		show_no_patrol_message()
		_change_state(EnemyState.IDLE)
		return

	set_initial_patrol_point()
	attach_to_patrol_points()	

func _physics_process(delta: float) -> void:
	if enemyState == EnemyState.DEAD:
		velocity = Vector3.ZERO
		return;

	if enemyState == EnemyState.PATROLLING:
		patrol(delta)
	if enemyState == EnemyState.IDLE:
		velocity = Vector3.ZERO
	if enemyState == EnemyState.FOLLOWING:
		_follow_target(delta)

	if isEnemyInRange:
		velocity = Vector3.ZERO
		_face_target(delta, attack_turn_speed)
		_update_attack_windup(delta)
	elif enemyState == EnemyState.FOLLOWING and targetToFollow != null:
		_face_target(delta, follow_turn_speed)
	else:
		look_at_current_direction(delta)
	move_and_slide()

func _follow_target(delta: float):
	super.follow_target(targetToFollow, delta, speed)

func patrol(delta: float):
	# Check if the enemy is within a certain distance of the patrol point

	if currentPatrolPoint != null:
		# Move towards the patrol point
		super.move_to_point(currentPatrolPoint, delta, speed)

func attach_to_patrol_points():
	# Attach the enemy to the patrol points
	for point in patrolPoints:
		point.patrolPointReached.connect(patrol_point_reached)

func set_initial_patrol_point():
	# Set the initial patrol point to the first one in the list
	if patrolPoints.size() > 0:
		currentPatrolPoint = patrolPoints[0]
	else:
		show_no_patrol_message()
		return

func show_no_patrol_message():
	push_warning("No patrol points set for GlobrcSmall: %s" % name)

func look_at_current_direction(delta: float):
	super.rotate_rig_to_velocity(_rig, delta)

func _face_target(delta: float, turn_speed: float) -> void:
	if targetToFollow == null:
		return
	var to_target := targetToFollow.global_position - _rig.global_position
	to_target.y = 0.0
	if to_target.length_squared() <= 0.001:
		return
	var target_angle := atan2(to_target.x, to_target.z)
	_rig.global_rotation.y = lerp_angle(_rig.global_rotation.y, target_angle, turn_speed * delta)

func _update_attack_windup(delta: float) -> void:
	if not canAttack or targetToFollow == null or not _is_facing_target():
		_attack_windup_remaining = 0.0
		return
	_attack_windup_remaining += delta
	if _attack_windup_remaining >= attack_windup_time:
		_attack_windup_remaining = 0.0
		attack()

func _is_facing_target() -> bool:
	if targetToFollow == null:
		return false
	var to_target := targetToFollow.global_position - _rig.global_position
	to_target.y = 0.0
	if to_target.length_squared() <= 0.001:
		return true
	var target_angle := atan2(to_target.x, to_target.z)
	return absf(angle_difference(_rig.global_rotation.y, target_angle)) <= deg_to_rad(attack_facing_angle_degrees)

func patrol_point_reached():
	if enemyState == EnemyState.FOLLOWING or enemyState == EnemyState.DEAD:
		return

	
	_change_state(EnemyState.IDLE)
	var random = randi() % 3 + 3
	await get_tree().create_timer(random, false).timeout
	if enemyState == EnemyState.FOLLOWING:
		return

	get_next_patrol_point()
	_change_state(EnemyState.PATROLLING)

# Patrol points should be managed by a dedicated patrol manager/prefab.
func get_next_patrol_point():
	var indexOfCurrentPatrolPoint := patrolPoints.find(currentPatrolPoint)
	if indexOfCurrentPatrolPoint != -1:
		if indexOfCurrentPatrolPoint < patrolPoints.size() - 1:
			currentPatrolPoint = patrolPoints[indexOfCurrentPatrolPoint + 1]
		else:
			currentPatrolPoint = patrolPoints[0]
	else:
		currentPatrolPoint = patrolPoints[0]

func attack():
	if not canAttack:
		return

	canAttack = false
	can_attack_timer.start()

	_animation_tree.set("parameters/mele_attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_player_search_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		_stop_out_of_bounds_timer_if_possible()
		targetToFollow = body
		_change_state(EnemyState.FOLLOWING)

func _on_player_out_of_bounds_timer_timeout() -> void:
		targetToFollow = null
		isEnemyInRange = false
		_attack_windup_remaining = 0.0
		_change_state(EnemyState.PATROLLING if patrolPoints.size() > 0 else EnemyState.IDLE)
		_stop_out_of_bounds_timer_if_possible()

func _on_player_search_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		_start_out_of_bounds_timer_if_possible()

func _start_out_of_bounds_timer_if_possible() -> void:
	if is_dead():
		return
	if not is_inside_tree():
		return
	if player_out_of_bounds_timer == null:
		return
	if not player_out_of_bounds_timer.is_inside_tree():
		return
	player_out_of_bounds_timer.start()

func _stop_out_of_bounds_timer_if_possible() -> void:
	if player_out_of_bounds_timer == null:
		return
	if not player_out_of_bounds_timer.is_inside_tree():
		return
	player_out_of_bounds_timer.stop()


func _on_hitable_area_body_entered(body:Node3D) -> void:
	if is_dead():
		return

	if body.is_in_group("MainPlayer"):
		isEnemyInRange = true
		_attack_windup_remaining = 0.0

func _on_hitable_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		isEnemyInRange = false
		_attack_windup_remaining = 0.0

func _on_melee_attack_animation_start() -> void:
	weapon_hit_collision_shape.disabled = false
	
func _on_melee_attack_animation_end() -> void:
	weapon_hit_collision_shape.disabled = true

func _on_weapon_hit_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		if body.has_method("take_damage"):
			body.take_damage()

func _on_can_attack_timer_timeout() -> void:
	canAttack = true

	_attack_windup_remaining = 0.0

func get_hit():
	if is_dead():
		return
	die()

func die():
	_change_state(EnemyState.DEAD)
	velocity = Vector3.ZERO
	isEnemyInRange = false
	canAttack = false
	weapon_hit_collision_shape.set_deferred("disabled", true)
	body_collider.set_deferred("disabled", true)
	await get_tree().create_timer(death_hide_delay, false).timeout
	_finish_death()

func is_dead() -> bool:
	return enemyState == EnemyState.DEAD

func _change_state(newState: EnemyState) -> void:
	if enemyState == EnemyState.DEAD:
		return
	enemyState = newState

func _finish_death() -> void:
	if _death_finished:
		return
	_death_finished = true
	_rig.visible = false
	if death_particles:
		if not death_particles.finished.is_connected(queue_free):
			death_particles.finished.connect(queue_free)
		death_particles.restart()
		death_particles.emitting = true
	else:
		queue_free()
