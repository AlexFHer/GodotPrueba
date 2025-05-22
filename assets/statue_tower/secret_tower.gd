class_name SecretTower extends Node3D

@onready var secret_tower: Node3D = $Model
@onready var tower_moving_audio_stream_player: AudioStreamPlayer3D = %AudioStreamPlayer

@export var activated_position_y := 0.0
@export var move_speed := 0.2

var activated := false

func activate_secret_tower() -> void:
	secret_tower.visible = true
	activated = true
	tower_moving_audio_stream_player.play()
	print("Secret tower activated")

func _process(delta: float) -> void:
	if activated:
		position.y = lerp(position.y, activated_position_y, move_speed * delta)
		if abs(position.y - activated_position_y) < 0.1:
			position.y = activated_position_y
			activated = false
			tower_moving_audio_stream_player.stop()
