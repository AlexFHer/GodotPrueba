extends SceneTree

var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func wait_seconds(seconds: float) -> void:
	await create_timer(seconds, true).timeout
func _run() -> void:
	var stage = load("res://scenes/tests/teleport_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	var player = stage.get_node("Player")
	var source = stage.get_node("WellA")
	var destination = stage.get_node("WellB")
	source.source_hold = 0.15
	destination.destination_hold = 0.15
	destination.jump_duration = 0.5
	destination.landing_hold = 0.15
	await wait_seconds(0.15)
	var previous_camera := root.get_camera_3d()
	check(previous_camera == player.get_node("CameraPivot/MainCharacterCamera"), "Well camera stole the player camera on level startup")
	var layer: int = player.collision_layer
	var mask: int = player.collision_mask
	player.global_position = source.entry_point.global_position
	await wait_seconds(0.15)
	check(player.is_teleporting(), "Entering well did not begin travel")
	check(player.is_gameplay_input_locked(), "Travel must lock gameplay input")
	check(root.get_camera_3d() == source.camera, "Source camera not selected")
	var life: int = player.life
	player.take_damage()
	check(player.life == life, "Player took damage during cinematic")
	var position_before_pause: Vector3 = player.global_position
	paused = true
	await wait_seconds(0.15)
	check(player.global_position.is_equal_approx(position_before_pause), "Travel moved while paused")
	paused = false
	await wait_seconds(0.6)
	check(root.get_camera_3d() == source.camera and not player.visible, "Source hold must show well with player hidden")
	await wait_seconds(0.18)
	check(root.get_camera_3d() == destination.camera, "Destination camera not selected")
	await wait_seconds(0.3)
	check(player.visible and player.global_position.y > 0.3, "Exit must rise in a jumping arc")
	await wait_seconds(0.6)
	check(not player.is_teleporting(), "Travel lock was not released")
	check(root.get_camera_3d() == previous_camera, "Player camera was not restored")
	check(player.collision_layer == layer and player.collision_mask == mask, "Collision state was not restored")
	check(player.global_position.distance_to(destination.exit_point.global_position) < 0.2, "Player did not land at ExitPoint")
	# Landing inside an arrival trigger must not create a return loop.
	destination.exit_point.position = Vector3(0, 0.05, 0)
	player.global_position = source.entry_point.global_position
	await wait_seconds(1.8)
	check(not player.is_teleporting(), "Arrival inside trigger immediately teleported again")
	check(root.get_camera_3d() == previous_camera, "Arrival block did not keep player camera")
	await wait_seconds(0.2)
	check(not player.is_teleporting(), "Arrival retriggered after collision restoration")
	player.global_position = Vector3(4, 0.1, 3)
	await wait_seconds(0.15)
	# Interrupted travel restores the original location and camera.
	player.global_position = source.entry_point.global_position
	await wait_seconds(0.15)
	check(player.is_teleporting(), "Second entry did not begin travel")
	destination.queue_free()
	await wait_seconds(0.1)
	check(not player.is_teleporting() and player.visible, "Removing destination left player locked or hidden")
	check(root.get_camera_3d() == previous_camera, "Interrupted travel did not restore camera")
	check(player.collision_layer == layer, "Interrupted travel did not restore collision")
	print("TELEPORT SEQUENCE: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	stage.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
