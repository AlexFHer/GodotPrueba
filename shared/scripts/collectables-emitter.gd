class_name CollectablesEmitter extends Node

signal mithrilPickedUp(levelName: String, amount: int)
signal bookPickedUp(levelName: String, amount: int)

func _get_level(source: Node) -> Node:
	for level: Node in get_tree().get_nodes_in_group("collectable_levels"):
		if level.collectable_scope == source or level.collectable_scope.is_ancestor_of(source):
			return level
	push_error("Collectible has no level manager: %s" % source.get_path())
	return null

func _get_id(source: Node, level: Node) -> String:
	var id: String = source.collectableId
	if id.is_empty():
		# Prototype fallback. Authored level instances should have explicit IDs.
		id = str(level.collectable_scope.get_path_to(source))
	return id

func is_collected(source: Node) -> bool:
	var level := _get_level(source)
	return level != null and LevelCollectablesData.has_collectable(level.levelName, _get_id(source, level))

func emitMithrilPickedUp(amount: int, source: Node) -> bool:
	return _collect("mithril", amount, source)

func emitBooksPickedUp(amount: int, source: Node) -> bool:
	return _collect("book", amount, source)

func _collect(kind: String, amount: int, source: Node) -> bool:
	var level := _get_level(source)
	if level == null or not LevelCollectablesData.collect(level.levelName, _get_id(source, level), kind, amount):
		return false
	if kind == "mithril":
		mithrilPickedUp.emit(level.levelName, amount)
	else:
		bookPickedUp.emit(level.levelName, amount)
	return true
