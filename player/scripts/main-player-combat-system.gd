extends Node

const NORMAL_ATTACK_ANIMATIONS := [
	&"Potma_Attack",
	&"Potma_Attack2",
	&"Potma_Attack3",
]
const ANIMATION_START_GRACE_FRAMES := 3
const STAFF_HIT_REQUEST := &"parameters/StaffHitOneShot/request"
const STAFF_HIT_ACTIVE := &"parameters/StaffHitOneShot/active"
const STAFF_THROW_REQUEST := &"parameters/StaffThrowOneShot/request"
const STAFF_THROW_ACTIVE := &"parameters/StaffThrowOneShot/active"
const HIT_REACTION_ACTIVE := &"parameters/HitOneShot/active"
const DEATH_REACTION_ACTIVE := &"parameters/DieOneShot/active"

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var _attack_reset_timer: Timer = %AttackResetTimer
@onready var _combo_reset_timer: Timer = %ComboResetTimer
@onready var _shoot_position: Node3D = %ShootPosition
@onready var _rig: Node3D = %Rig
@onready var _staff_collision: CollisionShape3D = %StaffCollision
@onready var _staff_area := _staff_collision.get_parent() as Area3D
@onready var _potmaSounds: PotmaSounds = %PotmaSounds
@onready var _active_potion_service = get_node("/root/ActivePotionEffectService")
@onready var _player := owner as MainPlayer
@onready var _staff_trail_particle: GPUParticles3D = %StaffTrailParticle
@onready var _normal_attack_animation_node := (
	(_animation_tree.tree_root as AnimationNodeBlendTree).get_node(&"Attack")
	as AnimationNodeAnimation
)

var _can_fire_attack := true
var _was_gameplay_input_locked := false
var _was_attack_recovery_blocked := false
var _is_drinking := false
var _dash_recovery_pending := false
var _damage_recovery_pending := false
var _damage_reaction_was_active := false
var _damage_reaction_start_grace_frames := 0

var _combo_step := 0
var _normal_attack_active := false
var _normal_attack_one_shot_was_active := false
var _normal_attack_start_grace_frames := 0
var _queued_next_attack := false
var _pending_next_attack := false
var _attack_generation := 0
var _damaged_targets_this_swing: Array[Node] = []

var _fire_attack_active := false
var _fire_attack_one_shot_was_active := false
var _fire_attack_start_grace_frames := 0


func _ready() -> void:
	_attack_reset_timer.timeout.connect(_enable_fire_attack)
	_combo_reset_timer.timeout.connect(_on_combo_reset_timer_timeout)
	_set_staff_collision(false)
	_disable_staff_trail_particle()


func _process(_delta: float) -> void:
	_update_attack_interruption_recovery()
	var gameplay_input_locked := _is_gameplay_input_locked()
	if gameplay_input_locked:
		if not _was_gameplay_input_locked:
			_cancel_active_attack()
		_was_gameplay_input_locked = true
		return

	_was_gameplay_input_locked = false
	var attack_recovery_blocked := _is_attack_recovery_blocked()
	if attack_recovery_blocked:
		if not _was_attack_recovery_blocked:
			_cancel_active_attack()
		_was_attack_recovery_blocked = true
		return

	_was_attack_recovery_blocked = false
	_update_normal_attack_animation_state()
	_update_fire_attack_animation_state()
	_try_start_pending_normal_attack()

	if Input.is_action_just_pressed("attack"):
		attack()


func attack() -> void:
	if _is_gameplay_input_locked() or _is_attack_recovery_blocked():
		return

	if _is_fire_potion_active():
		if not _can_fire_attack or _fire_attack_active:
			return
		_cancel_normal_attack()
		_play_staff_fire_animation()
		_disable_fire_attack()
		return

	if _fire_attack_active:
		return

	_handle_normal_attack_input()


func _handle_normal_attack_input() -> void:
	if _normal_attack_active:
		if _combo_step < NORMAL_ATTACK_ANIMATIONS.size() - 1:
			_queued_next_attack = true
		return

	if _pending_next_attack:
		return

	if not _combo_reset_timer.is_stopped() and _combo_step < NORMAL_ATTACK_ANIMATIONS.size() - 1:
		_combo_reset_timer.stop()
		_start_normal_attack(_combo_step + 1)
		return

	_reset_combo_progress()
	_start_normal_attack(0)


func _start_normal_attack(step: int) -> void:
	if step < 0 or step >= NORMAL_ATTACK_ANIMATIONS.size():
		_reset_combo_progress()
		return
	if _normal_attack_animation_node == null:
		GameLog.error("Normal attack AnimationTree node is missing")
		_reset_combo_progress()
		return

	_combo_reset_timer.stop()
	_combo_step = step
	_pending_next_attack = false
	_queued_next_attack = false
	_normal_attack_active = true
	_normal_attack_one_shot_was_active = false
	_normal_attack_start_grace_frames = ANIMATION_START_GRACE_FRAMES
	_attack_generation += 1
	_damaged_targets_this_swing.clear()

	_normal_attack_animation_node.animation = NORMAL_ATTACK_ANIMATIONS[_combo_step]
	_potmaSounds.staffHitSoundAudioStream.play()
	_enable_staff_trail_particle()
	_set_staff_collision(true)
	_animation_tree.set(STAFF_HIT_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	_damage_current_staff_overlaps_after_physics(_attack_generation)


func _update_normal_attack_animation_state() -> void:
	if not _normal_attack_active:
		return

	var one_shot_active := bool(_animation_tree.get(STAFF_HIT_ACTIVE))
	if one_shot_active:
		_normal_attack_one_shot_was_active = true
		return

	if _normal_attack_one_shot_was_active:
		_finish_normal_attack()
		return

	_normal_attack_start_grace_frames -= 1
	if _normal_attack_start_grace_frames <= 0:
		GameLog.warn("Normal attack animation failed to start")
		_cancel_normal_attack()


func _finish_normal_attack() -> void:
	_normal_attack_active = false
	_normal_attack_one_shot_was_active = false
	_normal_attack_start_grace_frames = 0
	_set_staff_collision(false)
	_disable_staff_trail_particle()
	_damaged_targets_this_swing.clear()

	if _combo_step >= NORMAL_ATTACK_ANIMATIONS.size() - 1:
		_reset_combo_progress()
		return

	if _queued_next_attack:
		_queued_next_attack = false
		_pending_next_attack = true
		return

	_combo_reset_timer.start()


func _try_start_pending_normal_attack() -> void:
	if not _pending_next_attack or _normal_attack_active:
		return
	if bool(_animation_tree.get(STAFF_HIT_ACTIVE)):
		return
	if _is_gameplay_input_locked() or _is_attack_recovery_blocked():
		_cancel_normal_attack()
		return

	_start_normal_attack(_combo_step + 1)


func _on_combo_reset_timer_timeout() -> void:
	if _normal_attack_active or _pending_next_attack:
		return
	_reset_combo_progress()


func _reset_combo_progress() -> void:
	_combo_reset_timer.stop()
	_combo_step = 0
	_queued_next_attack = false
	_pending_next_attack = false


func _play_staff_fire_animation() -> void:
	_fire_attack_active = true
	_fire_attack_one_shot_was_active = false
	_fire_attack_start_grace_frames = ANIMATION_START_GRACE_FRAMES
	_animation_tree.set(STAFF_THROW_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _update_fire_attack_animation_state() -> void:
	if not _fire_attack_active:
		return

	var one_shot_active := bool(_animation_tree.get(STAFF_THROW_ACTIVE))
	if one_shot_active:
		_fire_attack_one_shot_was_active = true
		return

	if _fire_attack_one_shot_was_active:
		_clear_fire_attack_state()
		return

	_fire_attack_start_grace_frames -= 1
	if _fire_attack_start_grace_frames <= 0:
		GameLog.warn("Fire attack animation failed to start")
		_clear_fire_attack_state()


func _clear_fire_attack_state() -> void:
	_fire_attack_active = false
	_fire_attack_one_shot_was_active = false
	_fire_attack_start_grace_frames = 0


func _fire_projectile() -> void:
	if not _fire_attack_active:
		return
	if _is_gameplay_input_locked() or _is_attack_recovery_blocked():
		return

	var instance = FireProjectile.new_fire_projectile()
	instance.position = _shoot_position.global_position
	instance.rotation = _rig.rotation
	get_tree().root.add_child(instance)


func _on_fireball_animation_fire() -> void:
	_fire_projectile()


func attack_animation_started() -> void:
	if _normal_attack_active and not _staff_trail_particle.emitting:
		_enable_staff_trail_particle(false)


func attack_animation_ended() -> void:
	pass


func _on_staff_hit_animation_end() -> void:
	if _normal_attack_active:
		_set_staff_collision(false)


func _is_fire_potion_active() -> bool:
	return _active_potion_service.current_active_potion == PotionTypes.PotionType.Fire


func _disable_fire_attack() -> void:
	_can_fire_attack = false
	_attack_reset_timer.start()


func _enable_fire_attack() -> void:
	_can_fire_attack = true


func _set_staff_collision(enabled: bool) -> void:
	_staff_collision.set_deferred(&"disabled", not enabled)


func _on_staff_area_3d_body_entered(body: Node3D) -> void:
	_damage_node_with_staff(body)


func _on_staff_area_3d_area_entered(area: Area3D) -> void:
	_damage_node_with_staff(area)


func _damage_current_staff_overlaps_after_physics(attack_generation: int) -> void:
	await get_tree().physics_frame
	if attack_generation != _attack_generation or not _normal_attack_active:
		return

	for body in _staff_area.get_overlapping_bodies():
		_damage_node_with_staff(body)
	for area in _staff_area.get_overlapping_areas():
		_damage_node_with_staff(area)


func _damage_node_with_staff(node: Node) -> void:
	if (
		not _normal_attack_active
		or _is_gameplay_input_locked()
		or _is_attack_recovery_blocked()
	):
		return
	if node == _player or _damaged_targets_this_swing.has(node):
		return
	if not node.is_in_group("CanGetHit") or not node.has_method("get_hit"):
		return

	_damaged_targets_this_swing.append(node)
	node.get_hit()


func _cancel_normal_attack() -> void:
	_attack_generation += 1
	_animation_tree.set(STAFF_HIT_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	_normal_attack_active = false
	_normal_attack_one_shot_was_active = false
	_normal_attack_start_grace_frames = 0
	_damaged_targets_this_swing.clear()
	_reset_combo_progress()
	_set_staff_collision(false)
	_disable_staff_trail_particle()
	if _potmaSounds.staffHitSoundAudioStream.is_playing():
		_potmaSounds.staffHitSoundAudioStream.stop()


func _cancel_active_attack() -> void:
	_cancel_normal_attack()
	_animation_tree.set(STAFF_THROW_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	_clear_fire_attack_state()


func _on_attack_interruption_requested(reason: int) -> void:
	match reason:
		MainPlayer.AttackInterruptionReason.DASH:
			_dash_recovery_pending = true
		MainPlayer.AttackInterruptionReason.DAMAGE:
			_damage_recovery_pending = true
			_damage_reaction_was_active = _is_hit_or_death_reaction_active()
			_damage_reaction_start_grace_frames = ANIMATION_START_GRACE_FRAMES
		_:
			GameLog.warn("Unknown attack interruption reason: %d" % reason)
	_cancel_active_attack()


func _on_potion_drink_started(_uses_left_slot: bool, _uses_right_slot: bool) -> void:
	_is_drinking = true
	_cancel_active_attack()


func _on_potion_drink_finished() -> void:
	_is_drinking = false


func _is_gameplay_input_locked() -> bool:
	return _player != null and _player.is_gameplay_input_locked()


func _is_attack_recovery_blocked() -> bool:
	if _is_drinking or _dash_recovery_pending or _damage_recovery_pending:
		return true
	return _is_dash_active() or _is_hit_or_death_reaction_active()


func _is_dash_active() -> bool:
	return _player != null and _player.isDashing


func _is_hit_or_death_reaction_active() -> bool:
	if _player != null and _player.life <= 0:
		return true
	return (
		bool(_animation_tree.get(HIT_REACTION_ACTIVE))
		or bool(_animation_tree.get(DEATH_REACTION_ACTIVE))
	)


func _update_attack_interruption_recovery() -> void:
	if _dash_recovery_pending and not _is_dash_active():
		_dash_recovery_pending = false

	if not _damage_recovery_pending:
		return

	if _is_hit_or_death_reaction_active():
		_damage_reaction_was_active = true
		return

	if _damage_reaction_was_active:
		_clear_damage_recovery()
		return

	_damage_reaction_start_grace_frames -= 1
	if _damage_reaction_start_grace_frames <= 0:
		GameLog.warn("Damage reaction failed to start")
		_clear_damage_recovery()


func _clear_damage_recovery() -> void:
	_damage_recovery_pending = false
	_damage_reaction_was_active = false
	_damage_reaction_start_grace_frames = 0


func _enable_staff_trail_particle(should_restart: bool = true) -> void:
	if should_restart:
		_staff_trail_particle.restart()
	_staff_trail_particle.emitting = true


func _disable_staff_trail_particle() -> void:
	if not _staff_trail_particle.emitting:
		return
	_staff_trail_particle.restart()
	_staff_trail_particle.emitting = false
