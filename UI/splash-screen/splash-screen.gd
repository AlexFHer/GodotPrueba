extends Node

func _ready() -> void:
	await get_tree().create_timer(10).timeout
	get_tree().change_scene_to_file("res://UI/main_menu/MainScene.tscn")
