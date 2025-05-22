extends Node

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var _attack_reset_timer: Timer = %AttackResetTimer
@onready var _shoot_position: Node3D = %ShootPosition
@onready var _rig: Node3D = %Rig
@onready var _staff_collision: CollisionShape3D = %StaffCollision
@onready var _potmaSounds: PotmaSounds = %PotmaSounds

var current_active_potion: PotionTypes.PotionType = PotionTypes.PotionType.None
var _can_attack := true

func _ready() -> void:
	PlayerPotions.potionEffectFinished.connect(_on_potion_effect_finished)
	PlayerPotions.potionUsed.connect(_on_potion_used)
	_attack_reset_timer.timeout.connect(_enable_attack)
	_set_staff_collision(false)

func _process(_delta: float) -> void:
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
	var instance = FireProjectile.new_fire_projectile();
	instance.position = _shoot_position.global_position;
	instance.rotation = _rig.rotation
	get_tree().root.add_child(instance)

func _on_potion_used(potion_type: PotionTypes.PotionType) -> void:
	if potion_type == PotionTypes.PotionType.Fire:
		current_active_potion = PotionTypes.PotionType.Fire

func _on_potion_effect_finished(potion_type: PotionTypes.PotionType) -> void:
	if potion_type == PotionTypes.PotionType.Fire:
		current_active_potion = PotionTypes.PotionType.None

func _on_fireball_animation_fire() -> void:
	_fire_projectile()

func attack() -> void:
	if current_active_potion == PotionTypes.PotionType.Fire:
		_play_staff_fire_animation()
	else:
		_play_staff_hit_animation()
	
	_disable_attack()
	
func _disable_attack() -> void:
	_can_attack = false
	_attack_reset_timer.start()
	
func _enable_attack() -> void:
	_can_attack = true
	
func _set_staff_collision(enabled: bool) -> void:
	_staff_collision.disabled = !enabled

func _on_staff_area_3d_body_entered(body:Node3D) -> void:
	if body.is_in_group("CanGetHit"):
		if body.has_method("get_hit"):
			body.get_hit()
