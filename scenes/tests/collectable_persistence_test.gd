extends Node

@onready var root: Window = get_tree().root

# Run twice with -- --collectables-test write/read and an isolated APPDATA.
const MYTHRIL = preload("res://assets/collectable/mythril/mythril1/mythril1.tscn")
const BOOK = preload("res://assets/collectable/book/book.tscn")
const CHEST = preload("res://assets/chests/normal_chest/chest.tscn")
const MAGIC_CHEST = preload("res://assets/chests/magic_chest/magic_chest.tscn")
const MANAGER = preload("res://assets/levels/levelManager.tscn")
var failures := 0

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_level(id: String) -> Node3D:
	var scope := Node3D.new()
	scope.name = id
	var manager := MANAGER.instantiate()
	manager.levelName = id
	scope.add_child(manager)
	manager.owner = scope
	for entry in [[MYTHRIL, "mithril"], [BOOK, "book"], [CHEST, "chest"], [MAGIC_CHEST, "magic"]]:
		var item: Node = entry[0].instantiate()
		item.name = entry[1]
		item.collectableId = entry[1]
		scope.add_child(item)
	root.add_child(scope)
	return scope

func _run() -> void:
	if not ".collectable-test-user" in OS.get_user_data_dir():
		push_error("Refusing to test against a real user save. Set isolated APPDATA first.")
		get_tree().quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var writing := "write" in args
	var ledger := root.get_node("LevelCollectablesData")
	var emitter := root.get_node("CollectablesEmitterService")
	var a := make_level("test_a")
	var b := make_level("test_b")
	await get_tree().process_frame
	await get_tree().process_frame
	if writing:
		check(emitter.emitMithrilPickedUp(5, a.get_node("mithril")), "First pickup must save")
		check(not emitter.emitMithrilPickedUp(5, a.get_node("mithril")), "Duplicate must be rejected")
		check(emitter.emitBooksPickedUp(1, a.get_node("book")), "Book must save")
		root.get_node("PlayerInventory").keys = 1
		a.get_node("chest").open_chest()
		check(root.get_node("PlayerInventory").keys == 0, "Chest consumes one key")
		a.get_node("chest").open_chest()
		check(a.get_node("magic").add_number_of_mithrils(), "Magic chest must save")
		check(emitter.emitMithrilPickedUp(1, b.get_node("mithril")), "Same ID in another level is independent")
		check(not ledger.collect("test_a", "invalid", "book", -1), "Invalid amounts rejected")
	else:
		check(not a.has_node("mithril"), "Saved mithril must disappear on reload")
		check(not a.has_node("book"), "Saved book must disappear on reload")
		check(a.get_node("chest").opened, "Chest must restore opened state")
		check(a.get_node("magic").opened, "Magic chest must restore opened state")
		check(not a.get_node("magic").isForceFieldActive, "Saved magic chest has no force field")
		check(b.has_node("book"), "Other level book remains available")
		check(not emitter.emitMithrilPickedUp(10, a.get_node("chest")), "Reloaded reward cannot be paid again")
		check(not ledger._is_valid_save({"version": 1, "levels": {"broken": []}}), "Malformed ledger rejected")
	check(ledger.get_total("test_a", "mithril") == 25, "Level A total must be 25")
	check(ledger.get_total("test_a", "book") == 1, "Level A book must be retained")
	check(ledger.get_total("test_b", "mithril") == 1, "Level B total must stay separate")
	check(a.get_node("Level").levelCollectables.currentMithrils == 25, "HUD snapshot restores total")
	check(a.get_node("Level").inGameCollectablesUiControl.book_icon.visible, "HUD restores book icon")
	a.free()
	b.free()
	print("COLLECTABLE TEST ", "write" if writing else "read", ": ", failures, " failures")
	get_tree().quit(1 if failures else 0)
