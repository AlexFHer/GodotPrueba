extends Node

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var _attack_reset_timer: Timer = %AttackResetTimer
@onready var _shoot_position: Node3D = %ShootPosition
@onready var _rig: Node3D = %Rig
@onready var _staff_collision: CollisionShape3D = %StaffCollision
@onready var _potmaSounds: PotmaSounds = %PotmaSounds
@onready var _active_potion_service = get_node("/root/ActivePotionEffectService")
@onready var _player := owner as MainPlayer
@onready var _staff_trail_particle: GPUParticles3D = %StaffTrailParticle

var _can_attack := true
var _was_gameplay_input_locked := false

func _ready() -> void:
	_attack_reset_timer.timeout.connect(_enable_attack)
	_set_staff_collision(false)
	_disable_staff_trail_particle()

func _process(_delta: float) -> void:
	var gameplay_input_locked := _is_gameplay_input_locked()
	if gameplay_input_locked:
		if not _was_gameplay_input_locked:
			_cancel_active_attack()
		_was_gameplay_input_locked = true
		return

	_was_gameplay_input_locked = false
	if Input.is_action_just_pressed("attack"):
		if _can_attack:
			attack()

func _play_staff_hit_animation() -> void:
	_potmaSounds.staffHitSoundAudioStream.play()
	_animation_tree.set("parameters/StaffHitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	_set_staff_collision(true)

func _on_staff_hit_animation_end() -> void:
	_set_staff_collision(false)

func _play_staff_fire_animation() -> void:
	_animation_tree.set("parameters/StaffThrowOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _fire_projectile() -> void:
	if _is_gameplay_input_locked():
		return
	print("FIRE PROJECTILE")
	var instance = FireProjectile.new_fire_projectile();
	instance.position = _shoot_position.global_position;
	instance.rotation = _rig.rotation
	get_tree().root.add_child(instance)

func _on_fireball_animation_fire() -> void:
	print("FIREBALL ANIMATION FIRE")
	_fire_projectile()

func attack() -> void:
	if _is_gameplay_input_locked() or not _can_attack:
		return
	if _is_fire_potion_active():
		_play_staff_fire_animation()
	else:
		_play_staff_hit_animation()
	
	_disable_attack()

func attack_animation_started() -> void:
	_enable_staff_trail_particle()

func attack_animation_ended() -> void:
	_disable_staff_trail_particle()

func _is_fire_potion_active() -> bool:
	return _active_potion_service.current_active_potion == PotionTypes.PotionType.Fire
	
func _disable_attack() -> void:
	_can_attack = false
	_attack_reset_timer.start()
	
func _enable_attack() -> void:
	_can_attack = true
	
func _set_staff_collision(enabled: bool) -> void:
	_staff_collision.disabled = !enabled

func _on_staff_area_3d_body_entered(body:Node3D) -> void:
	if _is_gameplay_input_locked() or _staff_collision.disabled:
		return
	if body.is_in_group("CanGetHit"):
		if body.has_method("get_hit"):
			body.get_hit()

func _on_staff_area_3d_area_entered(area:Area3D) -> void:
	if _is_gameplay_input_locked() or _staff_collision.disabled:
		return
	if area.is_in_group("CanGetHit"):
		if area.has_method("get_hit"):
			area.get_hit()


func _cancel_active_attack() -> void:
	_animation_tree.set(
		"parameters/StaffHitOneShot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	)
	_animation_tree.set(
		"parameters/StaffThrowOneShot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	)
	_set_staff_collision(false)
	if _potmaSounds.staffHitSoundAudioStream.is_playing():
		_potmaSounds.staffHitSoundAudioStream.stop()


func _is_gameplay_input_locked() -> bool:
	return _player != null and _player.is_gameplay_input_locked()

func _enable_staff_trail_particle() -> void:
	_staff_trail_particle.emitting = true

func _disable_staff_trail_particle() -> void:
	_staff_trail_particle.restart()
	_staff_trail_particle.emitting = false