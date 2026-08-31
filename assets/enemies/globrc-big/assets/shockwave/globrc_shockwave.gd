extends Node3D


@export var max_radius: float = 10.0
@export var speed: float = 8.0

@export var ring_width: float = 0.8
@export var hit_height: float = 0.6
@export var torus_thickness: float = 0.35

@export var damage: float = 20.0


@onready var detection_area: Area3D = $DetectionArea
@onready var ring: MeshInstance3D = $Ring

var current_radius: float = 0.0

var damaged_bodies: Array[Node3D] = []

func _ready() -> void:
	_update_visual()

	var collision: CollisionShape3D = $DetectionArea/CollisionShape3D

	print("=== SHOCKWAVE RUNTIME ===")
	print("Area existe: ", detection_area != null)
	print("Collision existe: ", collision != null)
	print("Shape: ", collision.shape)
	print("Disabled: ", collision.disabled)
	print("Area monitoring: ", detection_area.monitoring)
	print("Area mask: ", detection_area.collision_mask)

	if collision.shape is CylinderShape3D:
		var cylinder: CylinderShape3D = collision.shape as CylinderShape3D
		print("Radius: ", cylinder.radius)
		print("Height: ", cylinder.height)

	print("=========================")


func _physics_process(delta):
	current_radius += speed * delta

	_update_visual()
	_check_damage()

	if current_radius >= max_radius:
		queue_free()


func _update_visual() -> void:
	var torus: TorusMesh = ring.mesh as TorusMesh

	if torus == null:
		return

	var half_thickness: float = torus_thickness / 2.0

	torus.inner_radius = maxf(
		0.01,
		current_radius - half_thickness
	)

	torus.outer_radius = current_radius + half_thickness

func _on_detection_area_body_entered(body: Node) -> void:
	if body is MainPlayer:
		_check_damage()

func _check_damage() -> void:
	print("ENTRO EN CHECK DAMAGE")

	var bodies: Array[Node3D] = detection_area.get_overlapping_bodies()

	print("CUERPOS DETECTADOS: ", bodies.size())

	for body: Node3D in bodies:
		print("CUERPO: ", body.name)

		if body in damaged_bodies:
			continue

		if not body.has_method("take_damage"):
			continue

		var difference: Vector3 = body.global_position - global_position

		var horizontal_distance: float = Vector2(
			difference.x,
			difference.z
		).length()

		var height_difference: float = absf(difference.y)

		var inner_radius: float = current_radius - ring_width / 2.0
		var outer_radius: float = current_radius + ring_width / 2.0

		var touching_ring: bool = (
			horizontal_distance >= inner_radius
			and horizontal_distance <= outer_radius
		)

		var touching_ground_wave: bool = height_difference <= hit_height

		print(
			"Ring: ", touching_ring,
			" | Ground: ", touching_ground_wave
		)

		if touching_ring and touching_ground_wave:
			body.take_damage()
			damaged_bodies.append(body)
