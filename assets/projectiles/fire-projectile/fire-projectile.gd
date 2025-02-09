extends Area3D

@export var projectileStats: ProjectileStats;
var speed = 10

func _enter_tree() -> void:
	await get_tree().create_timer(projectileStats.lifeTime).timeout
	queue_free();

func _process(delta: float) -> void:
	position.z -= speed * delta;
	
