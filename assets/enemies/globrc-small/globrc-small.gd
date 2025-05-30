class_name GlobrcSmall extends Enemy

@onready var _rig: Node3D = $Rig
@onready var _animation_tree: AnimationTree = $Rig/AnimationTree
@onready var player_out_of_bounds_timer: Timer = $Rig/PlayerSearchArea/PlayerOutOfBoundsTimer
@onready var weapon_hit_collision_shape: CollisionShape3D = $Rig/WeaponHitArea/WeaponHitCollision
@onready var can_attack_timer: Timer = $canAttackTimer

@export var patrolPoints: Array[PatrolPoint] = [];

@export var speed: float = 250.0
@export var attackDamage: int = 1

const ROTATION_SENSIVITY := 10;

var currentPatrolPoint: PatrolPoint = null;

var targetToFollow: Node3D = null

var isEnemyInRange  := false
var canAttack := true;

enum EnemyState {
	IDLE,
	PATROLLING,
	FOLLOWING,
	ATTACKING,
	DEAD
}
var enemyState: EnemyState = EnemyState.PATROLLING

func _ready():
	if patrolPoints.size() == 0:
		show_no_patrol_message()
		return

	player_out_of_bounds_timer.connect("timeout", _on_player_out_of_bounds_timer_timeout)
	can_attack_timer.connect("timeout", _on_can_attack_timer_timeout)
	weapon_hit_collision_shape.disabled = true
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
		follow_target(delta)

	if isEnemyInRange:
		velocity = Vector3.ZERO
	look_at_current_direction(delta)
	move_and_slide()

func follow_target(delta: float):
	if targetToFollow == null:
		return

	move_to_point(targetToFollow, delta)

func patrol(delta: float):
	# Check if the enemy is within a certain distance of the patrol point

	if currentPatrolPoint != null:
		# Move towards the patrol point
		move_to_point(currentPatrolPoint, delta)

func attach_to_patrol_points():
	# Attach the enemy to the patrol points
	for point in patrolPoints:
		point.patrolPointReached.connect(patrol_point_reached)

func move_to_point(point: Node3D, delta: float):
	# Move towards the patrol point
	var direction = (point.global_position - global_transform.origin).normalized()
	# remove any y component
	direction.y = 0
	velocity = direction * speed * delta
	
	# Check if the enemy has reached the point
	if global_transform.origin.distance_to(point.global_position) < 0.2:
		velocity = Vector3.ZERO
		return

func set_initial_patrol_point():
	# Set the initial patrol point to the first one in the list
	if patrolPoints.size() > 0:
		currentPatrolPoint = patrolPoints[0]
	else:
		show_no_patrol_message()
		return

func show_no_patrol_message():
	print("No patrol points set for GlobrcSmall. Please set patrol points in the inspector. ", name)

func look_at_current_direction(delta: float):
	if velocity.length() > 0:
		var targetAngle := Vector3.BACK.signed_angle_to(velocity, Vector3.UP)
		_rig.global_rotation.y = lerp_angle(_rig.rotation.y, targetAngle, ROTATION_SENSIVITY * delta)


func patrol_point_reached():
	if enemyState == EnemyState.FOLLOWING or enemyState == EnemyState.DEAD:
		return

	
	_change_state(EnemyState.IDLE)
	var random = randi() % 3 + 3
	await get_tree().create_timer(random).timeout
	if enemyState == EnemyState.FOLLOWING:
		return

	get_next_patrol_point()
	_change_state(EnemyState.PATROLLING)

# TODO: Pasarlo a un prefab que gestion los puntos de control
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
		player_out_of_bounds_timer.stop()
		targetToFollow = body
		_change_state(EnemyState.FOLLOWING)

func _on_player_out_of_bounds_timer_timeout() -> void:
		targetToFollow = null
		_change_state(EnemyState.PATROLLING)
		player_out_of_bounds_timer.stop()

func _on_player_search_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		player_out_of_bounds_timer.start()


func _on_hitable_area_body_entered(body:Node3D) -> void:
	if is_dead():
		return

	if body.is_in_group("MainPlayer"):
		isEnemyInRange = true
		attack()

func _on_hitable_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		isEnemyInRange = false

func _on_melee_attack_animation_start() -> void:
	weapon_hit_collision_shape.disabled = false
	
func _on_melee_attack_animation_end() -> void:
	weapon_hit_collision_shape.disabled = true

func _on_weapon_hit_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		if body.has_method("dealDamage"):
			body.dealDamage()

func _on_can_attack_timer_timeout() -> void:
	canAttack = true

	if isEnemyInRange:
		attack()

func get_hit():
	die()

func die():
	_change_state(EnemyState.DEAD)
	_animation_tree.set("parameters/DieOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func is_dead() -> bool:
	return enemyState == EnemyState.DEAD

func _change_state(newState: EnemyState) -> void:
	if enemyState == EnemyState.DEAD:
		return
	enemyState = newState