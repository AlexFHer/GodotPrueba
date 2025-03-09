extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var rig: Node3D = %Rig

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("PotmaIdle/ArmatureAction_001")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
