extends Node

var player
var player_in_chat_zone

func _on_chat_detection_area_body_entered(body):
    if body.has_method("player"):
        player = body
        player_in_chat_zone = true

func _on_chat_detection_area_body_exited(body):   
    if body.has_method("player"):
        player_in_chat_zone = false    