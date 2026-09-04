extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensivity := 0.25
@export_range(0.5, 10.0, 0.1) var preferredDistance := 3.0
@export_range(0.0, 1.5, 0.05) var collisionLookAhead := 0.55
@export_range(1.0, 30.0, 0.5) var collisionApproachSpeed := 18.0
@export_range(1.0, 30.0, 0.5) var collisionRecoverySpeed := 6.0

@onready var springArm: SpringArm3D = $SpringArm3D
@onready var playerCamera: Camera3D = %MainCharacterCamera

const MULTIPLIER = 10;

var cameraInputDirection := Vector2.ZERO
var currentCameraDistance := 3.0

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	springArm.spring_length = preferredDistance + collisionLookAhead
	currentCameraDistance = preferredDistance
	_updateCameraTransform()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func manageInputMouseMotion(event: InputEventMouseMotion) -> void:
	cameraInputDirection = event.screen_relative * mouse_sensivity

func manageInputJoypadMotion(event: InputEventJoypadMotion) -> void:
	var isXAxisMotion = event.axis == JOY_AXIS_RIGHT_X
	var isYAxisMotion = event.axis == JOY_AXIS_RIGHT_Y
	
	if  isXAxisMotion:
		if abs(event.axis_value) > 0.1:
			cameraInputDirection.x = event.axis_value * 2
	if  isYAxisMotion:
		if abs(event.axis_value) > 0.1:
			cameraInputDirection.y = event.axis_value * 2

func _process(delta: float) -> void:
	manageSelfRotation(delta);
	_updateCameraCollision(delta)


func manageSelfRotation(delta: float) -> void:
	var axisXMotion = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(axisXMotion) > 0.1:
		rotation.y -= axisXMotion * MULTIPLIER * mouse_sensivity * delta
	
	var axisYMotion = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(axisYMotion) > 0.1:
		rotation.x += axisYMotion * MULTIPLIER * mouse_sensivity * delta
		rotation.x = clamp(rotation.x, -PI / 6.0, PI / 3.0)
	
	# cameraInputDirection = Vector2.ZERO

func resetMotion() -> void:
	cameraInputDirection = Vector2.ZERO

func _updateCameraCollision(delta: float) -> void:
	var hitLength: float = springArm.get_hit_length()
	var targetDistance: float = clampf(
		hitLength - collisionLookAhead,
		0.0,
		preferredDistance
	)
	var smoothingSpeed := (
		collisionApproachSpeed
		if targetDistance < currentCameraDistance
		else collisionRecoverySpeed
	)
	var smoothingWeight := 1.0 - exp(-smoothingSpeed * delta)

	currentCameraDistance = lerpf(
		currentCameraDistance,
		targetDistance,
		smoothingWeight
	)
	# Never leave the camera behind the collision point if an obstacle appears
	# suddenly. The extra probe distance normally makes this clamp unnecessary.
	currentCameraDistance = minf(currentCameraDistance, hitLength)
	_updateCameraTransform()

func _updateCameraTransform() -> void:
	var armTransform := springArm.transform
	var cameraOrigin := (
		armTransform.origin
		+ armTransform.basis.z.normalized() * currentCameraDistance
	)
	playerCamera.transform = Transform3D(armTransform.basis, cameraOrigin)
