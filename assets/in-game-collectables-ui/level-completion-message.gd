extends MarginContainer

@export var display_duration := 4.0
var _animation: Tween

func show_completion() -> void:
	if _animation != null:
		_animation.kill()
	modulate.a = 0.0
	show()
	_animation = create_tween()
	_animation.tween_property(self, "modulate:a", 1.0, 0.3)
	_animation.tween_interval(display_duration)
	_animation.tween_property(self, "modulate:a", 0.0, 0.4)
	_animation.tween_callback(hide)
