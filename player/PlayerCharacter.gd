


extends CharacterBody3D

@onready var _rig: Node3D = $Rig;
@onready var _camera: Camera3D = %MainCharacterCamera;

@onready var animation_player: AnimationPlayer = $Rig/Armature/Potma/AnimationPlayer
@onready var animation_tree: AnimationTree = $Rig/PlayerAnimationTree

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
var lastMovementDirection := Vector3.FORWARD
var gravity := -20;

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
	velocity.y += JUMP_FORCE;
	disableJump();

func megaJump() -> void:
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
	
	move_and_slide();

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
	else:
		gravity = ORIGINAL_GRAVITY

func process_movement(delta) -> void:
	var rawInput := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var moveDirection := forward * rawInput.y + right * rawInput.x
	moveDirection.y = 0.0
	moveDirection = moveDirection.normalized()
	
	var yVelocity := velocity.y;
	velocity.y = 0;
	velocity = velocity.move_toward(moveDirection * speed, ACCELERATION * delta)
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

func _deactivate_improved_speed() -> void:
	speed = NORMAL_SPEED;

func _on_potion_used(potionType: PotionTypes.PotionType) -> void:
	if potionType == PotionTypes.PotionType.Jump:
		jumpPotionUsed(potionType);
	if potionType == PotionTypes.PotionType.Speed:
		speedPotionUsed(potionType);
	if potionType == PotionTypes.PotionType.JumpAndSpeed:
		_activate_jump_speed_potion(potionType);

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
	
	animation_tree.set("parameters/JumpOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE);


func dealDamage() -> void:
	life -= 1;
	lifeChanged.emit(life)
	# Animation hit

func _is_player_moving_on_ground() -> bool:
	return is_on_floor() and (abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1)

func _is_player_not_moving_on_ground() -> bool:
	return is_on_floor() and (abs(velocity.x) < 0.1 or abs(velocity.z) < 0.1)
