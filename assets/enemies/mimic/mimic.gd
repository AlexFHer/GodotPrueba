class_name MimicChest extends Enemy

@onready var _rig: Node3D = $Rig
@onready var _animation_tree: AnimationTree = $Rig/AnimationTree
@onready var player_out_of_bounds_timer: Timer = $Rig/PlayerSearchArea/PlayerOutOfBoundsTimer
@onready var weapon_hit_collision_shape: CollisionShape3D = $Rig/WeaponHitArea/WeaponHitCollision
@onready var can_attack_timer: Timer = $canAttackTimer

@export var speed: float = 250.0
@export var attackDamage: int = 1

var targetToFollow: Node3D = null
var isEnemyInRange := false
var canAttack := true

enum EnemyState {
	IDLE,
	READY,
	FOLLOWING,
	DEAD
}
var enemyState: EnemyState = EnemyState.IDLE

func _ready():
	player_out_of_bounds_timer.connect("timeout", _on_player_out_of_bounds_timer_timeout)
	can_attack_timer.connect("timeout", _on_can_attack_timer_timeout)
	weapon_hit_collision_shape.disabled = true

func _physics_process(delta: float) -> void:
	if _is_dead():
		velocity = Vector3.ZERO
		return

	if enemyState == EnemyState.IDLE:
		velocity = Vector3.ZERO
		return;
		
	if enemyState == EnemyState.FOLLOWING:
		_follow_target(delta)
	
	if isEnemyInRange:
		velocity = Vector3.ZERO
	look_at_current_direction(delta)
	move_and_slide()

func _follow_target(delta: float):
	super.follow_target(targetToFollow, delta, speed)

func look_at_current_direction(delta: float):
	super.rotate_rig_to_velocity(_rig, delta)

func attack():
	if not canAttack:
		return

	canAttack = false
	can_attack_timer.start()
	_animation_tree.set("parameters/mele_attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_player_search_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		_stop_out_of_bounds_timer_if_possible()
		targetToFollow = body
		_set_state(EnemyState.FOLLOWING)

func _on_player_out_of_bounds_timer_timeout() -> void:
	targetToFollow = null
	_set_state(EnemyState.IDLE)
	_stop_out_of_bounds_timer_if_possible()

func _on_player_search_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		_start_out_of_bounds_timer_if_possible()

func _start_out_of_bounds_timer_if_possible() -> void:
	if _is_dead():
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

func _on_hitable_area_body_entered(body: Node3D) -> void:
	if _is_dead():
		return

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
	_set_state(EnemyState.DEAD)

func _is_dead() -> bool:
	return enemyState == EnemyState.DEAD

func _set_state(new_state: EnemyState) -> void:
	if enemyState == EnemyState.DEAD:
		return
	enemyState = new_state
