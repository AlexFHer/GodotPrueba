extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var wall = load("res://scenes/level1_stylized/breakable_wall/breakable_wall.tscn").instantiate()
	root.add_child(wall)
	await process_frame
	await process_frame
	check(wall.is_in_group("CanGetHit"), "Wall must receive combat hits")
	wall.get_hit()
	check(wall.remaining_hits == 2 and wall.wall.visible, "First hit keeps wall standing")
	await create_timer(0.08).timeout
	check(not wall.wall.position.is_equal_approx(Vector3.ZERO), "Hit shakes the visual mesh")
	wall.get_hit()
	check(wall.remaining_hits == 1 and wall.wall.visible, "Second hit keeps wall standing")
	wall.get_hit()
	wall.get_hit()
	await process_frame
	check(wall.remaining_hits == 0, "Extra hits cannot destroy twice")
	check(not wall.wall.visible and wall.collision.disabled, "Third hit removes wall and collision")
	check(wall.get_child_count() == 4, "Destruction creates both particle layers")
	await create_timer(2.1).timeout
	check(not is_instance_valid(wall), "Wall and effects clean up")
	print("BREAKABLE WALL TEST: ", failures, " failures")
	quit(1 if failures else 0)
