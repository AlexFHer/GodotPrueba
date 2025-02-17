


extends CharacterBody3D

@onready var _rig: Node3D = $Rig;
@onready var _camera: Camera3D = %MainCharacterCamera;

const JUMP_FORCE := 10.0;
const ROTATION_SENSIVITY := 10;
const NORMAL_SPEED := 15;
const IMPROVED_SPEED := 30;
const ACCELERATION := 30.0;
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


func jumpPotionUsed() -> void:
	activateMegaJump()
	await get_tree().create_timer(30).timeout
	deactivateMegaJump()

func manageSelfRotation(direction: Vector3) -> void:
	var target_direction = direction.normalized()
	if target_direction.length() < 0.01:
		target_direction += Vector3(0.01, 0, 0)  # Añadir un pequeño desplazamiento si están demasiado cerca
	_rig.look_at(global_transform.origin + target_direction, Vector3.UP)

func speedPotionUsed() -> void:
	speed = IMPROVED_SPEED;
	await get_tree().create_timer(30).timeout
	speed = NORMAL_SPEED;

func _on_potions_manager_potion_used(potion: Potion) -> void:
	if potion.type == PotionProperties.PotionType.Jump:
		jumpPotionUsed();
	if potion.type == PotionProperties.PotionType.Speed:
		speedPotionUsed();

func on_jump_buffer_timer_ends() -> void:
	jumpBuffer = false;

func determineJump() -> void:
	if canMegaJump:
		megaJump();
	else:
		jump()

func dealDamage() -> void:
	life -= 1;
	lifeChanged.emit(life)
