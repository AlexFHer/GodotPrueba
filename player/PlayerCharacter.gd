


extends CharacterBody3D

const PotionType = preload("res://assets/potions/shared/models/potion-types.gd").PotionType;

@export var cameraController: Node3D;
@onready var rig = $Rig;

const IN_AIR_SPEED = 5.0;
const JUMP_VELOCITY = 7.0
const ROTATION_SENSIVITY = 0.5;
const NORMAL_SPEED = 15;
const IMPROVED_SPEED = 30;

var speed = 15.0;
var canJump = true;
var canMegaJump = false;

func jump() -> void:
	velocity.y = JUMP_VELOCITY;
	disableJump();

func megaJump() -> void:
	velocity.y = JUMP_VELOCITY * 2;
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
	process_gravity(delta);
	
	move_and_slide();
	
	cameraController.position = lerp(cameraController.position, position, 0.1)

func process_jump() -> void:
	if is_on_floor():
		enableJump();
		# Handle jump.
	if !Input.is_action_just_pressed("jump"):
		return;
	
	if canJump:
		if canMegaJump:
			megaJump();
		else:
			jump()
	
	if canJump:
		jump()

func process_movement(delta) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var actualSpeed = speed
	if not is_on_floor():
		actualSpeed = IN_AIR_SPEED
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * actualSpeed
		velocity.z = direction.z * actualSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, actualSpeed)
		velocity.z = move_toward(velocity.z, 0, actualSpeed)
	
	# manageSelfRotation(direction, delta);

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
	rig.look_at(global_transform.origin + target_direction, Vector3.UP)

func speedPotionUsed() -> void:
	speed = IMPROVED_SPEED;
	await get_tree().create_timer(30).timeout
	speed = NORMAL_SPEED;

func _on_potions_manager_potion_used(potion: Potion) -> void:
	if potion.type == PotionType.Jump:
		jumpPotionUsed();
	if potion.type == PotionType.Speed:
		speedPotionUsed();
