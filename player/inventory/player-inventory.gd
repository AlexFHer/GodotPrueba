class_name PlayerInventoryService extends Node

@export var keys = 0;

signal numberOfKeysChanged(newNumberOfKeys: int);

func add_key() -> void:
	keys += 1
	numberOfKeysChanged.emit(keys)

func remove_key() -> void:
	if keys > 0:
		keys -= 1
		numberOfKeysChanged.emit(keys)