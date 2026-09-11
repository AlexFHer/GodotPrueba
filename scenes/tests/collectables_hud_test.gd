extends Node

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	var ui = preload("res://assets/in-game-collectables-ui/in-game-collectables-ui.tscn").instantiate()
	add_child(ui)
	var data := LevelCollectables.new()
	data.currentMithrils = 1250
	data.currentBooks = 1
	data.currentBabys = 3
	data.currentShards = 7
	ui.update_current_collectables(data)
	ui.display_duration = 0.5
	ui.show_collectables()
	check(ui.content.position.y < 0, "HUD starts above the screen")
	check(ui.bottom_content.position.y > 0, "Babys start below the screen")
	await get_tree().create_timer(0.5).timeout
	check(is_zero_approx(ui.content.position.y), "HUD arrives at its anchors")
	check(is_zero_approx(ui.bottom_content.position.y), "Babys arrive at the bottom anchor")
	check(ui.mithril_count_label.text == "1250", "Mithril counter")
	check(ui.book_count_label.text == "1", "Book counter")
	for count in range(4):
		data.currentBabys = count
		ui.update_current_collectables(data)
		for index in range(3):
			var expected = ui.baby_taken_texture if index < count else ui.baby_not_taken_texture
			check(ui.baby_icons[index].texture == expected, "Baby slot reflects collected count")
	check(ui.shard_count_label.text == "7", "Shard counter")
	for resolution in [Vector2i(1152, 648), Vector2i(1920, 1080), Vector2i(800, 600)]:
		get_window().size = resolution
		await get_tree().process_frame
		await get_tree().process_frame
		var viewport_rect := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
		for item in [ui.mithril_count_label, ui.book_count_label, ui.shard_count_label] + ui.baby_icons:
			check(viewport_rect.encloses(item.get_global_rect()), "Counter remains inside viewport")
	ui.display_duration = 1.0
	ui.show_collectables()
	await get_tree().create_timer(0.6).timeout
	check(ui.visible, "Select restarts duration without an old timer hiding the HUD")
	if "visual" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1152, 648)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.hud-preview.png")
	await get_tree().create_timer(1.3).timeout
	check(not ui.visible, "HUD hides after the refreshed duration")
	print("HUD TEST: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
