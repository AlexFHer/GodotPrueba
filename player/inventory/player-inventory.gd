class_name PlayerInventoryService extends Node

@export var keys = 0;

func add_key() -> void:
    keys += 1

func remove_key() -> void:
    if keys > 0:
        keys -= 1