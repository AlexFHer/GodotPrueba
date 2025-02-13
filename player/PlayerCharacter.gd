


extends CharacterBody3D

const PotionType = preload("res://assets/potions/shared/models/potion-types.gd").PotionType;

@onready var _rig: Node3D = $Rig;
@onready var _camera: Camera3D = %MainCharacterCamera;
@onready var _camera_pivot: Node3D = $CameraPivot;

const JUMP_FORCE := 10.0;
const ROTATION_SENSIVITY := 10;
const NORMAL_SPEED := 15;
const IMPROVED_SPEED := 30;
const ACCELERATION := 30.0;
const GRAVITY := -20;

# Movement

var speed := 10.0;
var lastMovementDirection := Vector3.FORWARD

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
	# process_gravity(delta);
	
	move_and_slide();
	
	# cameraController.position = lerp(cameraController.position, position, 0.1)

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
	velocity.y = yVelocity + GRAVITY * delta
	# manages rig rotation based on input
	if moveDirection.length() > 0.2:
		lastMovementDirection = moveDirection
	var targetAngle := Vector3.FORWARD.signed_angle_to(lastMovementDirection, Vector3.UP)
	_rig.global_rotation.y = lerp_angle(_rig.rotation.y, targetAngle, ROTATION_SENSIVITY * delta)
	

func process_gravity(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass

func jumpPotionUsed() -> void:
	activateMegaJump()
	await get_tree().create_timer(30).timeout
	deactivateMegaJump()

func manageSelfRotation(direction: Vector3, delta: float) -> void:
	var target_direction = direction.normalized()
	if target_direction.length() < 0.01:
		target_direction += Vector3(0.01, 0, 0)  # Añadir un pequeño desplazamiento si están demasiado cerca
	_rig.look_at(global_transform.origin + target_direction, Vector3.UP)

func speedPotionUsed() -> void:
	speed = IMPROVED_SPEED;
	await get_tree().create_timer(30).timeout
	speed = NORMAL_SPEED;

func _on_potions_manager_potion_used(potion: Potion) -> void:
	if potion.type == PotionType.Jump:
		jumpPotionUsed();
	if potion.type == PotionType.Speed:
		speedPotionUsed();

func on_jump_buffer_timer_ends() -> void:
	jumpBuffer = false;

func determineJump() -> void:
	if canMegaJump:
		megaJump();
	else:
		jump()
