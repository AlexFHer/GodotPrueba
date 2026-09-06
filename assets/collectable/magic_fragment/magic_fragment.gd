extends Node3D

signal popped
signal collected

@export var preview_pop_loop: bool = false
@export_range(0.5, 10.0) var preview_delay: float = 2.0
@export_range(0.0, 0.5) var float_height: float = 0.1
@export_range(0.5, 6.0) var float_period: float = 2.4
@export var pop_sound: AudioStream = preload("res://assets/collectable/magic_fragment/magic_pop_echo.wav")
@export_range(-30.0, 6.0) var pop_volume_db: float = -4.0

@onready var shell: MeshInstance3D = $MeshInstance3D
@onready var motes: GPUParticles3D = $InnerMotes
@onready var stars: GPUParticles3D = $InnerStars
@onready var core: MeshInstance3D = $RedCore
@onready var light: OmniLight3D = $MagicLight
@onready var burst: GPUParticles3D = $PopBurst

var _popping: bool = false
var _shell_scale: Vector3
var _light_energy: float
var _float_center: float
var _float_phase: float = 0.0

func _process(delta: float) -> void:
	if _popping:
		return
	# One continuous wave, without stops at the center or loop boundary.
	_float_phase = fposmod(_float_phase + TAU * delta / maxf(float_period, 0.01), TAU)
	position.y = _float_center + sin(_float_phase) * float_height

func _ready() -> void:
	_shell_scale = shell.scale
	_light_energy = light.light_energy
	_float_center = position.y
	if preview_pop_loop:
		_run_preview()

func pop() -> void:
	if _popping:
		return
	_popping = true
	var animation := create_tween()
	animation.tween_property(shell, "scale", _shell_scale * Vector3(1.15, 0.78, 1.15), 0.12)
	animation.tween_property(shell, "scale", _shell_scale * Vector3(0.87, 1.25, 0.87), 0.1)
	animation.tween_property(shell, "scale", _shell_scale * 1.3, 0.08)
	animation.parallel().tween_property(light, "light_energy", _light_energy * 1.8, 0.08)
	animation.tween_callback(_burst)
	animation.tween_property(light, "light_energy", 0.0, 0.3)
	animation.tween_interval(0.5)
	animation.tween_callback(func() -> void: popped.emit())
	if not preview_pop_loop:
		animation.tween_callback(queue_free)

func _burst() -> void:
	_play_pop_sound()
	shell.hide()
	motes.hide()
	stars.hide()
	core.hide()
	burst.restart()

func _play_pop_sound() -> void:
	if pop_sound == null:
		return
	# The tail survives the fragment's removal, but stays inside the level tree.
	var audio := AudioStreamPlayer3D.new()
	audio.stream = pop_sound
	audio.bus = &"SFX"
	audio.volume_db = pop_volume_db
	audio.unit_size = 4.0
	audio.max_distance = 24.0
	get_parent().add_child(audio)
	audio.global_position = global_position
	audio.finished.connect(audio.queue_free)
	audio.play()

func _run_preview() -> void:
	while is_inside_tree():
		await get_tree().create_timer(preview_delay, false).timeout
		pop()
		await popped
		shell.scale = _shell_scale
		light.light_energy = _light_energy
		shell.show()
		motes.show()
		stars.show()
		core.show()
		_popping = false


func _on_body_entered(body: Node3D) -> void:
	if _popping or not body.is_in_group("MainPlayer"):
		return
	pop()
	collected.emit()
