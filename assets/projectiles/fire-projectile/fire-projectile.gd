class_name FireProjectile extends Area3D

const fireProjectile := preload("res://assets/projectiles/fire-projectile/fire-projectile.tscn");

@export var projectileStats: ProjectileStats;
@onready var _audioStream: AudioStreamPlayer3D = %AudioStreamPlayer;

var speed = 10

func _enter_tree() -> void:
	_audioStream.play();
	await get_tree().create_timer(projectileStats.lifeTime).timeout
	queue_free();

func _process(delta: float) -> void:
	position += global_transform.basis * Vector3(0,0,-speed * delta)

static func new_fire_projectile() -> FireProjectile:
	var instance = fireProjectile.instantiate();
	return instance;

# func _on_body_entered(_body:Node3D) -> void:
# 	queue_free()