class_name FireProjectile extends Area3D

const fireProjectile := preload("res://assets/projectiles/fire-projectile/fire-projectile.tscn");

@export var projectileStats: ProjectileStats;
@export var _audioStream: AudioStreamPlayer3D;

var speed = 10

func _ready() -> void:
	_audioStream.play();

func _enter_tree() -> void:
	await get_tree().create_timer(projectileStats.lifeTime).timeout
	queue_free();

func _process(delta: float) -> void:
	position += global_transform.basis * Vector3(0,0,-speed * delta)

static func new_fire_projectile() -> FireProjectile:
	var instance = fireProjectile.instantiate();
	return instance;

func _on_body_entered(body:Node3D) -> void:
	print("Body entered: ", body.name);
	if body.is_in_group("CanGetHit") and !body.is_in_group("MainPlayer"):
		if body.has_method("get_hit"):
			body.get_hit();
	
	if !body.is_in_group("MainPlayer"):
		queue_free();
	
