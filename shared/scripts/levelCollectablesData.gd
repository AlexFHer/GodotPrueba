extends Node

const FILEPATH := "user://saves/collectables_v1.json"
var _levels: Dictionary = {}
var _loaded := false
var _load_failed := false

func _load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(FILEPATH):
		return
	var file := FileAccess.open(FILEPATH, FileAccess.READ)
	if file == null:
		_load_failed = true
	else:
		var data: Variant = JSON.parse_string(file.get_as_text())
		if _is_valid_save(data):
			_levels = data["levels"]
		else:
			_load_failed = true
	if _load_failed:
		push_error("Cannot load collectible progress; existing save will not be overwritten.")

func _is_valid_save(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not data.get("levels") is Dictionary:
		return false
	for level: Variant in data["levels"].values():
		if not level is Dictionary:
			return false
		for reward: Variant in level.values():
			if not reward is Dictionary or reward.get("kind") not in ["mithril", "book", "baby", "shard"]:
				return false
			var amount: Variant = reward.get("amount")
			if not (amount is float or amount is int):
				return false
			if not is_finite(float(amount)) or amount <= 0 or float(amount) != floor(float(amount)):
				return false
	return true

func has_collectable(levelName: String, collectableId: String) -> bool:
	_load_progress()
	return _levels.get(levelName, {}).has(collectableId)

func get_total(levelName: String, kind: String) -> int:
	_load_progress()
	var total := 0
	for reward: Dictionary in _levels.get(levelName, {}).values():
		if reward.get("kind") == kind:
			total += int(reward.get("amount", 0))
	return total

func collect(levelName: String, collectableId: String, kind: String, amount: int) -> bool:
	_load_progress()
	if _load_failed or levelName.is_empty() or collectableId.is_empty() or amount <= 0:
		return false
	if kind not in ["mithril", "book", "baby", "shard"] or has_collectable(levelName, collectableId):
		return false
	if not _levels.has(levelName):
		_levels[levelName] = {}
	_levels[levelName][collectableId] = {"kind": kind, "amount": amount}
	if not _save_progress():
		_levels[levelName].erase(collectableId)
		return false
	return true

func _save_progress() -> bool:
	var directory := ProjectSettings.globalize_path(FILEPATH.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Cannot create collectible save directory.")
		return false
	# Replace only after the complete ledger has been written successfully.
	var temporary := FILEPATH + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open collectible save for writing.")
		return false
	file.store_string(JSON.stringify({"version": 1, "levels": _levels}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(FILEPATH))
	if error != OK:
		push_error("Cannot save collectible progress: %s" % error_string(error))
	return error == OK
