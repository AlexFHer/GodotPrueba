class_name Enemy extends CharacterBody3D

var life := 1

const MOVE_COMPLETE_DISTANCE := 0.2
const DEFAULT_ROTATION_SENSITIVITY := 10.0

func follow_target(target: Node3D, delta: float, move_speed: float) -> void:
	if target == null:
		return

	move_to_point(target, delta, move_speed)

func move_to_point(point: Node3D, delta: float, move_speed: float) -> void:
	if point == null:
		return

	var direction := (point.global_position - global_transform.origin).normalized()
	direction.y = 0
	velocity = direction * move_speed * delta

	if global_transform.origin.distance_to(point.global_position) < MOVE_COMPLETE_DISTANCE:
		velocity = Vector3.ZERO

func rotate_rig_to_velocity(rig: Node3D, delta: float, rotation_sensitivity: float = DEFAULT_ROTATION_SENSITIVITY) -> void:
	if rig == null:
		return

	if velocity.length() > 0:
		var target_angle := Vector3.BACK.signed_angle_to(velocity, Vector3.UP)
		rig.global_rotation.y = lerp_angle(rig.rotation.y, target_angle, rotation_sensitivity * delta)
