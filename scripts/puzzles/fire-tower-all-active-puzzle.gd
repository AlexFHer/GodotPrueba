extends Node

@export var fire_towers: Array[FireTower] = [];

signal all_fire_towers_active()

func _ready() -> void:
	for fireTower in fire_towers:
		fireTower.fire_state.connect(on_fire_tower_activated)

func on_fire_tower_activated() -> void:
	for fireTower in fire_towers:
		if not fireTower.activated:
			return
	all_fire_towers_active.emit() 
	
