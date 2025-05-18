extends Area3D

var player: Node = null
var player_in_chat_zone: bool = false
var is_chatting: bool = false

@export var dialogue_text: String = "Hola, soy un NPC."

func _process(delta):
    if player_in_chat_zone and Input.is_action_just_pressed("ui_accept") and not is_chatting:
        start_dialogue()

func _on_body_entered(body: Node3D) -> void:
    if body.name == "Player":
        player = body
        player_in_chat_zone = true
        print("Jugador entró en zona de diálogo")

func _on_body_exited(body: Node3D) -> void:
    if body.name == "Player":
        player_in_chat_zone = false
        player = null
        print("Jugador salió de zona de diálogo")

func start_dialogue():
    is_chatting = true
    print(dialogue_text)
    # Aquí podrías enviar un mensaje al DialogueManager si tienes uno