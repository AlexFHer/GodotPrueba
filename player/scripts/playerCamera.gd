extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensivity := 0.25

const MULTIPLIER = 10;

var cameraInputDirection := Vector2.ZERO

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	#if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		#return;
	
	#if event is InputEventJoypadMotion:
		#manageInputJoypadMotion(event)
	#
	#if event is InputEventMouseMotion:
		#manageInputMouseMotion(event)
	pass

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
