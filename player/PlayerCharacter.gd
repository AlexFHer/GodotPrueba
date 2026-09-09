class_name MainPlayer extends CharacterBody3D

enum AttackInterruptionReason {
	DASH,
	DAMAGE,
	TELEPORT,
}

@onready var _rig: Node3D = $Rig;
@onready var _camera: Camera3D = %MainCharacterCamera;

@onready var animation_player: AnimationPlayer = $Rig/Armature/Potma/AnimationPlayer
@onready var animation_tree: AnimationTree = $Rig/PlayerAnimationTree
@onready var potmaSounds: PotmaSounds = %PotmaSounds
@onready var _ability_damage_area: Area3D = %AbilityDamageArea
@onready var _ability_damage_collision: CollisionShape3D = %AbilityDamageCollision

@export var checkpoint: Vector3 = Vector3.ZERO

const JUMP_FORCE := 13.0;
const MEGA_JUMP_MULTIPLIER := 2.5;
const DOUBLE_JUMP_FORCE := 14.0;
const DASH_SPEED := 35.0;
const DASH_DURATION_SECONDS := 0.22;
const DASH_COOLDOWN_SECONDS := 0.55;
const ROTATION_SENSIVITY := 10;
const NORMAL_SPEED := 10.0;
const IMPROVED_SPEED := 20.0;
const ACCELERATION := 20.0;
const ORIGINAL_GRAVITY := -30;
const DEATH_RESTART_DELAY_SECONDS := 0.5
const LOCOMOTION_BLEND_POSITION := &"parameters/Locomotion/WalkBlend/blend_position"
const LOCOMOTION_IDLE_BLEND := 0.0
const LOCOMOTION_WALK_BLEND := 1.0
const LOCOMOTION_RUN_BLEND := 2.0
const LOCOMOTION_BLEND_SPEED := 8.0

# life system

var life: int = 3;
signal lifeChanged(newLife: int);
signal attack_interruption_requested(reason: int)

# Movement

var speed := NORMAL_SPEED;
var isSprinting := false;
var lastMovementDirection := Vector3.FORWARD
var gravity := -25;
var _movement_input_strength := 0.0
var _locomotion_blend_position := LOCOMOTION_IDLE_BLEND
var _dialogue_controller: Node
var _was_gameplay_input_locked := false
var _teleport_controller: Node
var _teleport_collision_layer: int
var _teleport_collision_mask: int
var _teleport_tree_active: bool
var _teleport_animation_player: AnimationPlayer

var canMove := true;

# Jump
var jumpBuffer := false;
var jumpBufferTimer := 0.2;
var canJump := true;
var canMegaJump := false;
var canDoubleJump := false;
var hasDoubleJumpAvailable := false;
var isSecondJumpDamageActive := false;
var canDash := false;
var isDashing := false;
var dashReady := true;
var dashDirection := Vector3.FORWARD;
var damagedByAbility: Array[Node] = [];

func _init() -> void:
	PlayerPotions.potionUsed.connect(_on_potion_used);

func _ready() -> void:
	_set_ability_damage_enabled(false)

func jump() -> void:
	potmaSounds.jumpSoundAudioStream.play();
	velocity.y += JUMP_FORCE;
	disableJump();

func megaJump() -> void:
	potmaSounds.megaJumpSoundAudioStream.play();
	velocity.y += JUMP_FORCE * MEGA_JUMP_MULTIPLIER;
	disableJump();

func activateMegaJump() -> void:
	canMegaJump = true;

func deactivateMegaJump() -> void:
	canMegaJump = false;

func activateDoubleJump() -> void:
	canDoubleJump = true;
	hasDoubleJumpAvailable = true;

func deactivateDoubleJump() -> void:
	canDoubleJump = false;
	hasDoubleJumpAvailable = false;
	_stop_second_jump_damage();

func activateDash() -> void:
	canDash = true;
	dashReady = true;

func deactivateDash() -> void:
	canDash = false;
	isDashing = false;
	dashReady = true;
	_set_ability_damage_enabled(false);

func enableJump() -> void:
	canJump = true;

func disableJump() -> void:
	canJump = false;

func _physics_process(delta: float) -> void:
	if is_teleporting():
		return
	var gameplay_input_locked := is_gameplay_input_locked()
	if gameplay_input_locked and not _was_gameplay_input_locked:
		_cancel_dialogue_incompatible_actions()
	_was_gameplay_input_locked = gameplay_input_locked

	process_jump(gameplay_input_locked);
	process_dash(gameplay_input_locked);
	process_movement(delta, gameplay_input_locked);
	_update_locomotion_animation(delta)
	_process_moving_sound();
	
	move_and_slide();

func _process_moving_sound() -> void:
	if !is_moving() or !is_on_floor():
		if potmaSounds.walkSoundAudioStream.is_playing():
			potmaSounds.walkSoundAudioStream.stop();
		if potmaSounds.runSoundAudioStream.is_playing():
			potmaSounds.runSoundAudioStream.stop();
		return;
	
	if isSprinting:
		if !potmaSounds.runSoundAudioStream.is_playing():
			potmaSounds.runSoundAudioStream.play();
	else:
		if !potmaSounds.walkSoundAudioStream.is_playing():
			potmaSounds.walkSoundAudioStream.play();


func _play_walk_sound() -> void:
	if is_moving() and is_on_floor():
		potmaSounds.walkSoundAudioStream.play();
	else:
		potmaSounds.walkSoundAudioStream.stop();


func process_jump(gameplay_input_locked: bool) -> void:
	if not canMove:
		return
	if gameplay_input_locked:
		return

	if is_on_floor():
		enableJump();
		hasDoubleJumpAvailable = canDoubleJump;
		if isSecondJumpDamageActive:
			_stop_second_jump_damage();
		if jumpBuffer == true:
			determineJump()
		# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if canJump:
			determineJump();
		elif canDoubleJump and hasDoubleJumpAvailable:
			doubleJump();
		else:
			jumpBuffer = true;
			get_tree().create_timer(jumpBufferTimer, false).timeout.connect(on_jump_buffer_timer_ends)

func process_dash(gameplay_input_locked: bool) -> void:
	if gameplay_input_locked:
		return
	if Input.is_action_just_pressed("dash") and canMove and canDash and dashReady and not isDashing:
		_start_dash();

func process_movement(delta: float, gameplay_input_locked: bool) -> void:
	if isDashing and not gameplay_input_locked:
		_movement_input_strength = 1.0
		velocity = dashDirection * DASH_SPEED;
		return

	var rawInput := Vector2.ZERO
	if canMove and not gameplay_input_locked:
		rawInput = Input.get_vector("move-left", "move-right", "move-forward", "move-backwards");
	_movement_input_strength = rawInput.length()
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var moveDirection := forward * rawInput.y + right * rawInput.x
	moveDirection.y = 0.0
	moveDirection = moveDirection.normalized()
	
	var yVelocity := velocity.y;
	velocity.y = 0;
	# Cambia move_toward por interpolación directa para quitar el patinado
	if _movement_input_strength > 0.0:
		velocity = moveDirection * speed * _movement_input_strength
	else:
		velocity = Vector3.ZERO
	velocity.y = yVelocity + gravity * delta
	# manages rig rotation based on input
	if _movement_input_strength > 0.0:
		lastMovementDirection = moveDirection
	var targetAngle := Vector3.FORWARD.signed_angle_to(lastMovementDirection, Vector3.UP)
	_rig.global_rotation.y = lerp_angle(_rig.rotation.y, targetAngle, ROTATION_SENSIVITY * delta)


func _update_locomotion_animation(delta: float) -> void:
	var target_blend_position := LOCOMOTION_RUN_BLEND
	if not isDashing:
		var maximum_blend_position := LOCOMOTION_RUN_BLEND if isSprinting else LOCOMOTION_WALK_BLEND
		target_blend_position = _movement_input_strength * maximum_blend_position

	_locomotion_blend_position = move_toward(
		_locomotion_blend_position,
		target_blend_position,
		LOCOMOTION_BLEND_SPEED * delta
	)
	animation_tree.set(LOCOMOTION_BLEND_POSITION, _locomotion_blend_position)


func jumpPotionUsed(potionType: PotionTypes.PotionType) -> void:
	activateMegaJump()
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime, false).timeout
	deactivateMegaJump()

func speedPotionUsed(potionType: PotionTypes.PotionType) -> void:
	_activate_improved_speed();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime, false).timeout
	_deactivate_improved_speed();

func _activate_improved_speed() -> void:
	speed = IMPROVED_SPEED;
	isSprinting = true;

func _deactivate_improved_speed() -> void:
	speed = NORMAL_SPEED;
	isSprinting = false;

func _on_potion_used(potionType: PotionTypes.PotionType) -> void:
	if potionType == PotionTypes.PotionType.Jump:
		jumpPotionUsed(potionType);
	if potionType == PotionTypes.PotionType.Speed:
		speedPotionUsed(potionType);
	if potionType == PotionTypes.PotionType.JumpAndSpeed:
		_activate_jump_speed_potion(potionType);
	if potionType == PotionTypes.PotionType.JumpAndFire:
		_activate_jump_fire_potion(potionType);
	if potionType == PotionTypes.PotionType.SpeedAndFire:
		_activate_speed_fire_potion(potionType);


func _on_potion_drink_started(_uses_left_slot: bool, _uses_right_slot: bool) -> void:
	canMove = false;
	canJump = false;


func _on_potion_drink_finished() -> void:
	canMove = true;
	canJump = true

func _activate_jump_speed_potion(potionType: PotionTypes.PotionType) -> void:
	activateMegaJump()
	_activate_improved_speed();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime, false).timeout
	deactivateMegaJump();
	_deactivate_improved_speed();

func _activate_jump_fire_potion(potionType: PotionTypes.PotionType) -> void:
	activateDoubleJump();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime, false).timeout
	deactivateDoubleJump();

func _activate_speed_fire_potion(potionType: PotionTypes.PotionType) -> void:
	activateDash();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime, false).timeout
	deactivateDash();

func on_jump_buffer_timer_ends() -> void:
	jumpBuffer = false;

func determineJump() -> void:
	if canMegaJump:
		megaJump();
	else:
		jump()

func doubleJump() -> void:
	hasDoubleJumpAvailable = false;
	potmaSounds.megaJumpSoundAudioStream.play();
	velocity.y = DOUBLE_JUMP_FORCE;
	disableJump();
	_start_second_jump_damage();

func _start_dash() -> void:
	if is_gameplay_input_locked():
		return
	dashDirection = _get_dash_direction();
	isDashing = true;
	attack_interruption_requested.emit(AttackInterruptionReason.DASH)
	dashReady = false;
	_set_ability_damage_enabled(true);

	await get_tree().create_timer(DASH_DURATION_SECONDS, false).timeout
	isDashing = false;
	_set_ability_damage_enabled(false);

	await get_tree().create_timer(DASH_COOLDOWN_SECONDS, false).timeout
	dashReady = true;

func _get_dash_direction() -> Vector3:
	var rawInput := Input.get_vector("move-left", "move-right", "move-forward", "move-backwards");
	if not rawInput.is_zero_approx():
		var forward := _camera.global_basis.z
		var right := _camera.global_basis.x
		var inputDirection := forward * rawInput.y + right * rawInput.x
		inputDirection.y = 0.0
		return inputDirection.normalized()

	return lastMovementDirection.normalized()

func _start_second_jump_damage() -> void:
	if is_gameplay_input_locked():
		return
	isSecondJumpDamageActive = true;
	_set_ability_damage_enabled(true);

func _stop_second_jump_damage() -> void:
	isSecondJumpDamageActive = false;
	if not isDashing:
		_set_ability_damage_enabled(false);

func _set_ability_damage_enabled(enabled: bool) -> void:
	if enabled:
		damagedByAbility.clear()
	_ability_damage_collision.disabled = not enabled
	_ability_damage_area.monitoring = enabled
	_ability_damage_area.monitorable = enabled
	if enabled:
		call_deferred("_damage_current_ability_overlaps")

func _damage_current_ability_overlaps() -> void:
	if not isDashing and not isSecondJumpDamageActive:
		return
	for body in _ability_damage_area.get_overlapping_bodies():
		_damage_node_with_ability(body)
	for area in _ability_damage_area.get_overlapping_areas():
		_damage_node_with_ability(area)

func _on_ability_damage_area_body_entered(body: Node3D) -> void:
	_damage_node_with_ability(body)

func _on_ability_damage_area_area_entered(area: Area3D) -> void:
	_damage_node_with_ability(area)

func _damage_node_with_ability(node: Node) -> void:
	if is_gameplay_input_locked():
		return
	if not isDashing and not isSecondJumpDamageActive:
		return
	if node == self or damagedByAbility.has(node):
		return
	if not node.is_in_group("CanGetHit"):
		return
	if not node.has_method("get_hit"):
		return

	damagedByAbility.append(node)
	node.get_hit()


func take_damage() -> void:
	if is_teleporting():
		return
	attack_interruption_requested.emit(AttackInterruptionReason.DAMAGE)
	life -= 1;
	potmaSounds.getHitSoundAudioStream.play();
	lifeChanged.emit(life)
	animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);
	Input.start_joy_vibration(0, 0.5, 0.2, 0.4)
	checkIfPlayerIsDead();

func checkIfPlayerIsDead() -> void:
	if life <= 0:
		animation_tree.set("parameters/DieOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);
		await get_tree().create_timer(DEATH_RESTART_DELAY_SECONDS, false).timeout
		_trigger_game_over()

func _trigger_game_over() -> void:
	get_tree().reload_current_scene()

func _is_player_moving_on_ground() -> bool:
	return is_on_floor() and (abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1)

func _is_player_not_moving_on_ground() -> bool:
	return is_on_floor() and (abs(velocity.x) < 0.1 or abs(velocity.z) < 0.1)

func is_moving() -> bool:
	return abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1

func get_to_checkpoint() -> void:
	if is_teleporting():
		return
	position = checkpoint


func is_gameplay_input_locked() -> bool:
	if is_teleporting():
		return true
	if not is_instance_valid(_dialogue_controller):
		_dialogue_controller = get_tree().get_first_node_in_group(&"dialogue_controller")
	if _dialogue_controller == null or not _dialogue_controller.has_method(&"is_consuming_gameplay_input"):
		return false
	return bool(_dialogue_controller.call(&"is_consuming_gameplay_input"))


func is_teleporting() -> bool:
	return is_instance_valid(_teleport_controller)


func begin_teleport(controller: Node) -> bool:
	if life <= 0 or not canMove or is_gameplay_input_locked():
		return false
	_teleport_controller = controller
	_cancel_dialogue_incompatible_actions()
	velocity = Vector3.ZERO
	attack_interruption_requested.emit(AttackInterruptionReason.TELEPORT)
	potmaSounds.walkSoundAudioStream.stop()
	potmaSounds.runSoundAudioStream.stop()
	_teleport_collision_layer = collision_layer
	_teleport_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	_teleport_tree_active = animation_tree.active
	_teleport_animation_player = animation_tree.get_node(animation_tree.anim_player) as AnimationPlayer
	animation_tree.active = false
	return true


func set_teleport_pose(animation_name: StringName) -> void:
	if is_teleporting() and _teleport_animation_player.has_animation(animation_name):
		_teleport_animation_player.play(animation_name, 0.1)


func face_teleport_exit(direction: Vector3) -> void:
	direction.y = 0.0
	if not direction.is_zero_approx():
		lastMovementDirection = direction.normalized()
		_rig.global_rotation.y = Vector3.FORWARD.signed_angle_to(lastMovementDirection, Vector3.UP)


func end_teleport(controller: Node) -> void:
	if _teleport_controller != controller:
		return
	_teleport_animation_player.stop()
	animation_tree.active = _teleport_tree_active
	collision_layer = _teleport_collision_layer
	collision_mask = _teleport_collision_mask
	velocity = Vector3.ZERO
	_teleport_controller = null
	reset_physics_interpolation()


func _cancel_dialogue_incompatible_actions() -> void:
	jumpBuffer = false
	isDashing = false
	isSecondJumpDamageActive = false
	_movement_input_strength = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_locomotion_blend_position = LOCOMOTION_IDLE_BLEND
	animation_tree.set(LOCOMOTION_BLEND_POSITION, LOCOMOTION_IDLE_BLEND)
	_set_ability_damage_enabled(false)
