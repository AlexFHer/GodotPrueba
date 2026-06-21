class_name MainPlayer extends CharacterBody3D

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
const NORMAL_SPEED := 15;
const IMPROVED_SPEED := 20;
const ACCELERATION := 20.0;
const ORIGINAL_GRAVITY := -30;
const DRINK_MOVE_LOCK_SECONDS := 2.1
const DEATH_RESTART_DELAY_SECONDS := 0.5

# life system

var life: int = 3;
signal lifeChanged(newLife: int);

# Movement

var speed := 10.0;
var isSprinting := false;
var lastMovementDirection := Vector3.FORWARD
var gravity := -25;

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
	process_jump();
	process_dash();
	process_movement(delta);
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


func process_jump() -> void:
	if not canMove:
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
			get_tree().create_timer(jumpBufferTimer).timeout.connect(on_jump_buffer_timer_ends)

func process_dash() -> void:
	if Input.is_action_just_pressed("dash") and canMove and canDash and dashReady and not isDashing:
		_start_dash();

func process_movement(delta) -> void:
	if isDashing:
		velocity = dashDirection * DASH_SPEED;
		return

	var rawInput := Input.get_vector("move-left", "move-right", "move-forward", "move-backwards");
	if !canMove:
		rawInput = Vector2.ZERO;
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var moveDirection := forward * rawInput.y + right * rawInput.x
	moveDirection.y = 0.0
	moveDirection = moveDirection.normalized()
	
	var yVelocity := velocity.y;
	velocity.y = 0;
	# Cambia move_toward por interpolación directa para quitar el patinado
	if moveDirection.length() > 0.1:
		velocity = moveDirection * speed
	else:
		velocity = Vector3.ZERO
	velocity.y = yVelocity + gravity * delta
	# manages rig rotation based on input
	if moveDirection.length() > 0.2:
		lastMovementDirection = moveDirection
	var targetAngle := Vector3.FORWARD.signed_angle_to(lastMovementDirection, Vector3.UP)
	_rig.global_rotation.y = lerp_angle(_rig.rotation.y, targetAngle, ROTATION_SENSIVITY * delta)


func jumpPotionUsed(potionType: PotionTypes.PotionType) -> void:
	activateMegaJump()
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime).timeout
	deactivateMegaJump()

func speedPotionUsed(potionType: PotionTypes.PotionType) -> void:
	_activate_improved_speed();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime).timeout
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
	
	disable_can_move_due_drink_potion();

func disable_can_move_due_drink_potion() -> void:
	canMove = false;
	canJump = false;

	await get_tree().create_timer(DRINK_MOVE_LOCK_SECONDS).timeout
	canMove = true;
	canJump = true

func _activate_jump_speed_potion(potionType: PotionTypes.PotionType) -> void:
	activateMegaJump()
	_activate_improved_speed();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime).timeout
	deactivateMegaJump();
	_deactivate_improved_speed();

func _activate_jump_fire_potion(potionType: PotionTypes.PotionType) -> void:
	activateDoubleJump();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime).timeout
	deactivateDoubleJump();

func _activate_speed_fire_potion(potionType: PotionTypes.PotionType) -> void:
	activateDash();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime).timeout
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
	dashDirection = _get_dash_direction();
	isDashing = true;
	dashReady = false;
	_set_ability_damage_enabled(true);

	await get_tree().create_timer(DASH_DURATION_SECONDS).timeout
	isDashing = false;
	_set_ability_damage_enabled(false);

	await get_tree().create_timer(DASH_COOLDOWN_SECONDS).timeout
	dashReady = true;

func _get_dash_direction() -> Vector3:
	var rawInput := Input.get_vector("move-left", "move-right", "move-forward", "move-backwards");
	if rawInput.length() > 0.1:
		var forward := _camera.global_basis.z
		var right := _camera.global_basis.x
		var inputDirection := forward * rawInput.y + right * rawInput.x
		inputDirection.y = 0.0
		return inputDirection.normalized()

	return lastMovementDirection.normalized()

func _start_second_jump_damage() -> void:
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


func dealDamage() -> void:
	life -= 1;
	potmaSounds.getHitSoundAudioStream.play();
	lifeChanged.emit(life)
	animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);
	checkIfPlayerIsDead();

func checkIfPlayerIsDead() -> void:
	if life <= 0:
		animation_tree.set("parameters/DieOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);
		await get_tree().create_timer(DEATH_RESTART_DELAY_SECONDS).timeout
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
	position = checkpoint
