extends Node

const MANAGER = preload("res://assets/levels/levelManager.tscn")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_level(id: String, requirements: LevelCollectables) -> Node:
	var level := MANAGER.instantiate()
	level.levelName = id
	level.levelCollectables = requirements
	add_child(level)
	return level

func _ready() -> void:
	if not ".collectable-test-user" in OS.get_user_data_dir():
		push_error("Use isolated APPDATA containing .collectable-test-user")
		get_tree().quit(1)
		return
	var requirements := LevelCollectables.new()
	check(not requirements.is_complete(), "Empty levels must not complete")
	requirements.requiredMithrils = 5
	requirements.requiredBooks = 1
	requirements.requiredBabys = 1
	requirements.requiredShards = 1
	var level := make_level("completion_test", requirements)
	var banner: Control = level.completion_message
	banner.display_duration = 0.1
	for kind: String in ["mithril", "book", "baby", "shard"]:
		check(not banner.visible, "Every category is required")
		check(LevelCollectablesData.collect(level.levelName, kind, kind, 5 if kind == "mithril" else 1), "Pickup saves")
		level._on_collectable_picked_up("another_level", 1)
		check(not banner.visible, "Other levels cannot trigger completion")
		level._on_collectable_picked_up(level.levelName, 1)
	check(banner.visible, "Last collectible shows the completion banner")
	check(not get_tree().paused, "Completion does not pause gameplay")
	check(not requirements.is_complete(), "Authored configuration remains unchanged")
	var animation: Tween = banner._animation
	level._on_collectable_picked_up(level.levelName, 1)
	check(banner._animation == animation, "Repeated signals cannot restart the banner")
	get_tree().paused = true
	await get_tree().create_timer(0.9).timeout
	check(banner.visible and is_zero_approx(banner.modulate.a), "Pause freezes banner animation")
	get_tree().paused = false
	await get_tree().create_timer(0.9).timeout
	check(not banner.visible, "Banner hides after its duration")
	level.free()
	level = make_level("completion_test", requirements)
	check(not level.completion_message.visible, "Reloading completed progress does not announce again")
	level._on_collectable_picked_up(level.levelName, 1)
	check(not level.completion_message.visible, "Reload remains completed")
	var single := LevelCollectables.new()
	single.requiredBooks = 1
	single.currentBooks = 2
	check(single.is_complete(), "Zero targets and exceeded targets are supported")
	for locale: String in ["es", "en", "eu"]:
		TranslationServer.set_locale(locale)
		check(tr("ui_level_completed_100") != "ui_level_completed_100", "Completion translation: " + locale)
	print("LEVEL COMPLETION TEST: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
