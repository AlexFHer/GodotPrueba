

extends CharacterBody3D

const PotionType = preload("res://resources/potions/potion-types.gd").PotionType;
@export var cameraController: Node3D;

const speed: float = 6.0;
const inAirSpeed: float = 3.0;

const jump_velocity: float = 7.0
const rotationSensivity = 0.5;

var canJump: bool = true;

var potionsData: PotionsData = PotionsData.new();

func _ready() -> void:
	var newPotion = Potion.new();
	newPotion.name = "Blue potion";
	newPotion.type = PotionType.Blue;

func jump() -> void:
	velocity.y = jump_velocity;
	disableJump();

func megaJump() -> void:
	velocity.y = jump_velocity * 2;
	disableJump();

func enableJump() -> void:
	canJump = true;

func disableJump() -> void:
	canJump = false;

func _physics_process(delta: float) -> void:
	process_jump();
	process_movement();
	process_gravity(delta);
	
	move_and_slide();
	
	cameraController.position = lerp(cameraController.position, position, 0.1)

func process_jump() -> void:
	if is_on_floor():
		enableJump();
		# Handle jump.
	if !Input.is_action_just_pressed("ui_accept"):
		return;
	
	if canJump:
		jump()

func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var actualSpeed = speed
	if not is_on_floor():
		actualSpeed = inAirSpeed
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * actualSpeed
		velocity.z = direction.z * actualSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, actualSpeed)
		velocity.z = move_toward(velocity.z, 0, actualSpeed)

func process_gravity(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass
		#cameraController.rotate_y(deg_to_rad(-event.relative.x*rotationSensivity)); 