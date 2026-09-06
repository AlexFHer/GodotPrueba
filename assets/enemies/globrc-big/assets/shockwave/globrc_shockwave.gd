extends Node3D


@export var max_radius: float = 10.0
@export var speed: float = 8.0

@export var ring_width: float = 0.8
@export var hit_height: float = 0.6

@export var damage: float = 20.0


@onready var detection_area: Area3D = $DetectionArea
@onready var ring: MeshInstance3D = $Ring

var current_radius: float = 0.0

var damaged_bodies: Array[Node3D] = []

var electric_material: ShaderMaterial
var age: float = 0.0
var arc_materials: Array[ShaderMaterial] = []

func _create_electric_arcs() -> void:
	for index in range(2):
		var arc := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.975
		torus.outer_radius = 1.025
		torus.rings = 256
		torus.ring_segments = 6
		arc.mesh = torus
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Shader expansion exceeds the original unit torus bounds.
		arc.extra_cull_margin = max_radius + 1.0
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/enemies/globrc-big/assets/shockwave/electric_arcs.gdshader")
		material.set_shader_parameter("phase", float(index) * 0.47)
		arc.material_override = material
		arc_materials.append(material)
		add_child(arc)

func _ready() -> void:
	# Each simultaneous discharge owns its shader parameters and plane size.
	electric_material = ring.material_override.duplicate() as ShaderMaterial
	ring.material_override = electric_material
	var plane := ring.mesh.duplicate() as PlaneMesh
	var extent: float = max_radius + ring_width
	plane.size = Vector2.ONE * extent * 2.0
	ring.mesh = plane
	electric_material.set_shader_parameter("extent", extent)
	electric_material.set_shader_parameter("wave_width", ring_width)
	_create_electric_arcs()
	_update_visual()


func _physics_process(delta: float) -> void:
	age += delta
	current_radius += speed * delta

	_update_visual()
	_check_damage()

	if current_radius >= max_radius:
		queue_free()


func _update_visual() -> void:
	electric_material.set_shader_parameter("radius", current_radius)
	electric_material.set_shader_parameter("age", age)
	var fade: float = 1.0 - smoothstep(max_radius * 0.85, max_radius, current_radius)
	electric_material.set_shader_parameter("fade", fade)
	for material in arc_materials:
		material.set_shader_parameter("radius", current_radius)
		material.set_shader_parameter("age", age)
		material.set_shader_parameter("fade", fade)

func _on_detection_area_body_entered(body: Node) -> void:
	if body is MainPlayer:
		_check_damage()

func _check_damage() -> void:

	var bodies: Array[Node3D] = detection_area.get_overlapping_bodies()


	for body: Node3D in bodies:

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


		if touching_ring and touching_ground_wave:
			body.take_damage()
			damaged_bodies.append(body)
