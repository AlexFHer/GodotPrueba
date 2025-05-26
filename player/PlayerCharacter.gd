extends CharacterBody3D

@onready var _rig: Node3D = $Rig;
@onready var _camera: Camera3D = %MainCharacterCamera;

@onready var animation_player: AnimationPlayer = $Rig/Armature/Potma/AnimationPlayer
@onready var animation_tree: AnimationTree = $Rig/PlayerAnimationTree
@onready var potmaSounds: PotmaSounds = %PotmaSounds

@export var checkpoint: Vector3 = Vector3.ZERO

const JUMP_FORCE := 10.0;
const ROTATION_SENSIVITY := 10;
const NORMAL_SPEED := 15;
const IMPROVED_SPEED := 20;
const ACCELERATION := 20.0;
const ORIGINAL_GRAVITY := -30;
const PLANNING_GRAVITY := -10;

# life system

var life: int = 3;
signal lifeChanged(newLife: int);

# Movement

var speed := 10.0;
var isSprinting := false;
var isFloating := false;
var lastMovementDirection := Vector3.FORWARD
var gravity := -20;

var canMove := true;

# Jump
var jumpBuffer := false;
var jumpBufferTimer := 0.2;
var canJump := true;
var canMegaJump := false;

func _init() -> void:
	PlayerPotions.potionUsed.connect(_on_potion_used);

func _ready() -> void:
	pass

func jump() -> void:
	potmaSounds.jumpSoundAudioStream.play();
	velocity.y += JUMP_FORCE;
	disableJump();

func megaJump() -> void:
	potmaSounds.megaJumpSoundAudioStream.play();
	velocity.y += JUMP_FORCE * 2;
	disableJump();

func activateMegaJump() -> void:
	canMegaJump = true;

func deactivateMegaJump() -> void:
	canMegaJump = false;

func enableJump() -> void:
	canJump = true;

func disableJump() -> void:
	canJump = false;

func _physics_process(delta: float) -> void:
	process_jump();
	process_movement(delta);
	process_planning();
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
	if is_on_floor():
		enableJump();
		if jumpBuffer == true:
			determineJump()
		# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if canJump:
			determineJump();
		else:
			jumpBuffer = true;
			get_tree().create_timer(jumpBufferTimer).timeout.connect(on_jump_buffer_timer_ends)
			

func process_planning() -> void:
	if Input.is_action_pressed("jump") and not is_on_floor():
		gravity = PLANNING_GRAVITY
		isFloating = true
	else:
		gravity = ORIGINAL_GRAVITY
		isFloating = false

func process_movement(delta) -> void:
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
	
	disable_can_move_due_drink_potion();


# TODO: Implementarlo con la animacion correspondiente
func disable_can_move_due_drink_potion() -> void:
	canMove = false;
	canJump = false;

	await get_tree().create_timer(2.1).timeout
	canMove = true;
	canJump = true

func _activate_jump_speed_potion(potionType: PotionTypes.PotionType) -> void:
	activateMegaJump()
	_activate_improved_speed();
	var lifeTime = PotionsConfig.get_potion_properties(potionType).lifeTime
	await get_tree().create_timer(lifeTime).timeout
	deactivateMegaJump();
	_deactivate_improved_speed();

func on_jump_buffer_timer_ends() -> void:
	jumpBuffer = false;

func determineJump() -> void:
	if canMegaJump:
		megaJump();
	else:
		jump()


func dealDamage() -> void:
	life -= 1;
	potmaSounds.getHitSoundAudioStream.play();
	lifeChanged.emit(life)
	animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);
	checkIfPlayerIsDead();

func checkIfPlayerIsDead() -> void:
	if life <= 0:
		animation_tree.set("parameters/DieOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);
		await get_tree().create_timer(0.5).timeout
		# restart_game();
		get_tree().reload_current_scene()
		# TODO: implement game over

func _is_player_moving_on_ground() -> bool:
	return is_on_floor() and (abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1)

func _is_player_not_moving_on_ground() -> bool:
	return is_on_floor() and (abs(velocity.x) < 0.1 or abs(velocity.z) < 0.1)

func is_moving() -> bool:
	return abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1

func get_to_checkpoint() -> void:
	position = checkpoint

func floating() -> bool:
	return isFloating
