extends GPUParticles3D

@onready var shine: MeshInstance3D = $Shine

func play_pickup() -> void:
	restart()
	shine.show()
	shine.scale = Vector3.ONE * 0.05
	var tween := create_tween()
	tween.tween_property(shine, "scale", Vector3.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(shine, "scale", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(shine.hide)
