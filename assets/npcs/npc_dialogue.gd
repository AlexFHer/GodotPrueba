extends Area3D

var player: Node = null
var player_in_chat_zone: bool = false
var is_chatting: bool = false

@export var dialogue_scene: PackedScene
@export_file("*.json") var dialogue_file

@export var dialogue_text: String = "Hola, soy un NPC."

func _process(delta):
	if player_in_chat_zone and Input.is_action_just_pressed("ui_accept") and not is_chatting:
		start_dialogue()

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player = body
		player_in_chat_zone = true
		GameLog.debug("Player entered dialogue zone")

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_chat_zone = false
		player = null
		GameLog.debug("Player left dialogue zone")

func start_dialogue():
	is_chatting = true
	GameLog.debug("Starting NPC dialogue")
	var dialogue_instance = dialogue_scene.instantiate()
	get_tree().get_root().add_child(dialogue_instance)
	dialogue_instance.d_file = dialogue_file 
