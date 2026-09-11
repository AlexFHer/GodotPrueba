extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensivity := 0.25
@export_range(0.5, 10.0, 0.1) var preferredDistance := 3.0
@export_range(0.0, 1.5, 0.05) var collisionLookAhead := 0.55
@export_range(1.0, 30.0, 0.5) var collisionApproachSpeed := 18.0
@export_range(1.0, 30.0, 0.5) var collisionRecoverySpeed := 6.0
@export_range(-89.0, 0.0, 1.0, "degrees") var minPitchDegrees := -88.0
@export_range(0.0, 89.0, 1.0, "degrees") var maxPitchDegrees := 75.0
## Visible space around the player's upper body before scenery forces a zoom.
@export_range(0.1, 1.0, 0.05) var obstructionWidth := 0.45
@export_range(0.0, 1.0, 0.05) var obstructionHeight := 0.5
@export_group("First Person")
@export var firstPersonCameraOffset := Vector3(0.0, 1.2, 0.0)
@export var hideRigInFirstPerson := true

@onready var springArm: SpringArm3D = $SpringArm3D
@onready var playerCamera: Camera3D = %MainCharacterCamera
@onready var _playerRig: Node3D = %Rig

const MULTIPLIER = 10;
const VIEW_SAMPLE_SIDES := [0.0, -1.0, 1.0]

var cameraInputDirection := Vector2.ZERO
var currentCameraDistance := 3.0
var visibilityQuery := PhysicsRayQueryParameters3D.new()
var cameraShapeQuery := PhysicsShapeQueryParameters3D.new()
var _firstPersonActive := false
var _rigWasVisible := true

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	springArm.spring_length = preferredDistance + collisionLookAhead
	visibilityQuery.collision_mask = springArm.collision_mask
	visibilityQuery.hit_from_inside = true
	cameraShapeQuery.shape = springArm.shape
	cameraShapeQuery.collision_mask = springArm.collision_mask
	cameraShapeQuery.margin = springArm.margin
	currentCameraDistance = preferredDistance
	_updateCameraTransform()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("first_person"):
		set_first_person_active(not _firstPersonActive)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		manageInputMouseMotion(event)

func manageInputMouseMotion(event: InputEventMouseMotion) -> void:
	cameraInputDirection += event.screen_relative * mouse_sensivity

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

func _physics_process(delta: float) -> void:
	if _firstPersonActive:
		_updateFirstPersonCameraTransform()
		return
	_updateCameraCollision(delta)


func manageSelfRotation(delta: float) -> void:
	var axisXMotion = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(axisXMotion) > 0.1:
		cameraInputDirection.x += axisXMotion * MULTIPLIER * mouse_sensivity

	var axisYMotion = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(axisYMotion) > 0.1:
		cameraInputDirection.y += axisYMotion * MULTIPLIER * mouse_sensivity

	rotation.y -= cameraInputDirection.x * delta
	rotation.x += cameraInputDirection.y * delta
	rotation.x = clamp(rotation.x, deg_to_rad(minPitchDegrees), deg_to_rad(maxPitchDegrees))
	resetMotion()

func resetMotion() -> void:
	cameraInputDirection = Vector2.ZERO

func set_first_person_active(active: bool) -> void:
	if _firstPersonActive == active:
		return
	_firstPersonActive = active
	if _firstPersonActive:
		_rigWasVisible = _playerRig.visible
		if hideRigInFirstPerson:
			_playerRig.visible = false
		currentCameraDistance = 0.0
		_updateFirstPersonCameraTransform()
	else:
		_playerRig.visible = _rigWasVisible
		currentCameraDistance = preferredDistance
		_updateCameraTransform()

func is_first_person_active() -> bool:
	return _firstPersonActive

func _updateCameraCollision(delta: float) -> void:
	var hitLength: float = springArm.get_hit_length()
	var spaceState := get_world_3d().direct_space_state
	# A small prop can briefly cover part of the player without moving the
	# camera. Walls still retract it when all upper-body sightlines are blocked.
	if hitLength < preferredDistance + collisionLookAhead:
		if not _isViewBlocked(spaceState):
			hitLength = preferredDistance + collisionLookAhead
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
	# Visibility tolerance must never put the camera itself inside a prop.
	# Check the candidate and the short approach to it with the smaller sphere.
	currentCameraDistance = minf(
		currentCameraDistance,
		_getCameraClearance(spaceState, currentCameraDistance)
	)
	_updateCameraTransform()

func _isViewBlocked(spaceState: PhysicsDirectSpaceState3D) -> bool:
	var armTransform := springArm.global_transform
	visibilityQuery.from = armTransform.origin + armTransform.basis.z * preferredDistance
	var focus := armTransform.origin + Vector3.UP * obstructionHeight
	for side in VIEW_SAMPLE_SIDES:
		visibilityQuery.to = focus + armTransform.basis.x * obstructionWidth * side
		if spaceState.intersect_ray(visibilityQuery).is_empty():
			return false
	return true

func _getCameraClearance(spaceState: PhysicsDirectSpaceState3D, distance: float) -> float:
	var armTransform := springArm.global_transform
	var direction := armTransform.basis.z.normalized()
	cameraShapeQuery.transform = Transform3D(
		armTransform.basis, armTransform.origin + direction * distance
	)
	cameraShapeQuery.motion = Vector3.ZERO
	if not spaceState.intersect_shape(cameraShapeQuery, 1).is_empty():
		# Use a fresh full cast for a sudden collision; the spring arm may still
		# hold the previous physics tick's result after movement or rotation.
		cameraShapeQuery.transform = armTransform
		cameraShapeQuery.motion = direction * distance
		return maxf(0.0, distance * spaceState.cast_motion(cameraShapeQuery)[0] - springArm.margin)

	# Only protect the space close to the camera. Casting this from the player
	# would turn a tolerated foreground prop back into an immediate zoom.
	var approachDistance := minf(distance, collisionLookAhead)
	cameraShapeQuery.transform.origin -= direction * approachDistance
	cameraShapeQuery.motion = direction * (approachDistance + collisionLookAhead)
	var safeFraction: float = spaceState.cast_motion(cameraShapeQuery)[0]
	if safeFraction < 1.0:
		return maxf(0.0, distance - approachDistance
			+ (approachDistance + collisionLookAhead) * safeFraction - springArm.margin)
	return distance

func _updateCameraTransform() -> void:
	var armTransform := springArm.transform
	var cameraOrigin := (
		armTransform.origin
		+ armTransform.basis.z.normalized() * currentCameraDistance
	)
	playerCamera.transform = Transform3D(armTransform.basis, cameraOrigin)

func _updateFirstPersonCameraTransform() -> void:
	var cameraOrigin := (
		global_position
		+ global_transform.basis.x.normalized() * firstPersonCameraOffset.x
		+ Vector3.UP * firstPersonCameraOffset.y
		+ global_transform.basis.z.normalized() * firstPersonCameraOffset.z
	)
	playerCamera.global_transform = Transform3D(springArm.global_transform.basis, cameraOrigin)
