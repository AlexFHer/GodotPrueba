extends Area3D

@export var projectileStats: ProjectileStats;

func _enter_tree() -> void:
	print(projectileStats.lifeTime);
	await get_tree().create_timer(projectileStats.lifeTime).timeout
	queue_free();

func _process(delta: float) -> void:
	position.x += (position.x + 2) * delta
	
