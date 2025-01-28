extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensivity := 0.25

var cameraInputDirection := Vector2.ZERO

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	
	var isCameraMotion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if isCameraMotion:
		cameraInputDirection = event.screen_relative * mouse_sensivity

func _physics_process(delta: float) -> void:
	rotation.x += cameraInputDirection.y * delta
	rotation.x = clamp(rotation.x, -PI / 6.0, PI / 3.0)
	rotation.y -= cameraInputDirection.x * delta
	
	cameraInputDirection = Vector2.ZERO
