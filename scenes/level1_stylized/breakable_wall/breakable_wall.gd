extends StaticBody3D

@export_range(1, 10) var hit_points := 3
@export var shake_strength := 0.09
@onready var wall: MeshInstance3D = $Breakable_Wall
@onready var collision: CollisionShape3D = $CollisionShape3D_Breakable_Wall
var remaining_hits: int
var _broken := false
var _shake: Tween
var _rest_position: Vector3

func _ready() -> void:
	remaining_hits = hit_points
	_rest_position = wall.position

func get_hit() -> void:
	if _broken:
		return
	remaining_hits -= 1
	if _shake:
		_shake.kill()
	wall.position = _rest_position
	if remaining_hits <= 0:
		_break_wall()
		return
	_shake = create_tween()
	_shake.tween_method(_shake_wall, 0.0, 1.0, 0.28)
	_shake.tween_callback(func(): wall.position = _rest_position)

func _shake_wall(progress: float) -> void:
	var amplitude := shake_strength * (1.0 - progress)
	wall.position = _rest_position + Vector3(sin(progress * 38.0), sin(progress * 27.0) * 0.35, cos(progress * 32.0)) * amplitude

func _break_wall() -> void:
	_broken = true
	remove_from_group("CanGetHit")
	collision.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	wall.hide()
	_spawn_destruction()
	await get_tree().create_timer(2.0, false).timeout
	queue_free()

func _spawn_destruction() -> void:
	# Sample the actual imported triangles, whose origin is far from the wall.
	var points := PackedVector3Array()
	var faces := wall.mesh.get_faces()
	for index in range(0, faces.size(), 3):
		for sample_index in range(8):
			var u := randf()
			var v := randf()
			if u + v > 1.0:
				u = 1.0 - u
				v = 1.0 - v
			points.append(wall.transform * (faces[index] + u * (faces[index + 1] - faces[index]) + v * (faces[index + 2] - faces[index])))
	var rock := SphereMesh.new()
	rock.radius = 0.28
	rock.height = 0.48
	rock.radial_segments = 5
	rock.rings = 2
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.48, 0.38, 0.36)
	stone.roughness = 1.0
	stone.vertex_color_use_as_albedo = true
	rock.material = stone
	var fragments := _make_burst(points, rock, 38, 1.35)
	fragments.initial_velocity_min = 2.0
	fragments.initial_velocity_max = 5.0
	fragments.gravity = Vector3(0, -9.8, 0)
	fragments.angular_velocity_min = -180.0
	fragments.angular_velocity_max = 180.0
	fragments.scale_amount_min = 0.5
	fragments.scale_amount_max = 1.6
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(0.65, 1))
	shrink.add_point(Vector2(1, 0))
	fragments.scale_amount_curve = shrink
	fragments.restart()
	var puff := QuadMesh.new()
	puff.size = Vector2(1.4, 1.4)
	var dust_material := ShaderMaterial.new()
	dust_material.shader = preload("res://scenes/level1_stylized/breakable_wall/wall_dust.gdshader")
	puff.material = dust_material
	var dust := _make_burst(points, puff, 24, 1.0)
	dust.initial_velocity_min = 0.3
	dust.initial_velocity_max = 1.4
	dust.gravity = Vector3(0, 0.4, 0)
	dust.scale_amount_min = 0.6
	dust.scale_amount_max = 1.5
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.3))
	grow.add_point(Vector2(1, 1.4))
	dust.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.12, 0.45, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	dust.color_ramp = fade
	dust.restart()

func _make_burst(points: PackedVector3Array, mesh: Mesh, count: int, duration: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.mesh = mesh
	particles.amount = count
	particles.lifetime = duration
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = true
	particles.direction = Vector3.UP
	particles.spread = 100.0
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	particles.emission_points = points
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles
