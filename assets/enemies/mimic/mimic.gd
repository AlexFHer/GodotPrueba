class_name MimicChest extends Enemy

@onready var _rig: Node3D = $Rig
@onready var _animation_tree: AnimationTree = $Rig/AnimationTree
@onready var player_out_of_bounds_timer: Timer = $Rig/PlayerSearchArea/PlayerOutOfBoundsTimer
@onready var weapon_hit_collision_shape: CollisionShape3D = $Rig/WeaponHitArea/WeaponHitCollision
@onready var can_attack_timer: Timer = $canAttackTimer

@export var speed: float = 250.0
@export var attackDamage: int = 1

const ROTATION_SENSIVITY := 10

var targetToFollow: Node3D = null
var isEnemyInRange := false
var canAttack := true

enum EnemyState {
	IDLE,
	FOLLOWING,
	ATTACKING,
	DEAD
}
var enemyState: EnemyState = EnemyState.IDLE

func _ready():
	player_out_of_bounds_timer.connect("timeout", _on_player_out_of_bounds_timer_timeout)
	can_attack_timer.connect("timeout", _on_can_attack_timer_timeout)
	weapon_hit_collision_shape.disabled = true

func _physics_process(delta: float) -> void:
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

func move_to_point(point: Node3D, delta: float):
	var direction = (point.global_position - global_transform.origin).normalized()
	direction.y = 0
	velocity = direction * speed * delta

	if global_transform.origin.distance_to(point.global_position) < 0.2:
		velocity = Vector3.ZERO
		return

func look_at_current_direction(delta: float):
	if velocity.length() > 0:
		var targetAngle := Vector3.BACK.signed_angle_to(velocity, Vector3.UP)
		_rig.global_rotation.y = lerp_angle(_rig.rotation.y, targetAngle, ROTATION_SENSIVITY * delta)

func attack():
	if not canAttack:
		return

	canAttack = false
	can_attack_timer.start()
	_animation_tree.set("parameters/mele_attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_player_search_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		player_out_of_bounds_timer.stop()
		targetToFollow = body
		enemyState = EnemyState.FOLLOWING

func _on_player_out_of_bounds_timer_timeout() -> void:
	targetToFollow = null
	enemyState = EnemyState.IDLE
	player_out_of_bounds_timer.stop()

func _on_player_search_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		player_out_of_bounds_timer.start()

func _on_hitable_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		isEnemyInRange = true
		attack()

func _on_hitable_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		isEnemyInRange = false

func _on_melee_attack_animation_start() -> void:
	weapon_hit_collision_shape.disabled = false

func _on_melee_attack_animation_end() -> void:
	weapon_hit_collision_shape.disabled = true

func _on_weapon_hit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		if body.has_method("dealDamage"):
			body.dealDamage()

func _on_can_attack_timer_timeout() -> void:
	canAttack = true
	if isEnemyInRange:
		attack()

func die():
	enemyState = EnemyState.DEAD
