extends Area3D

@export var projectileStats: ProjectileStats;

func _process(delta: float) -> void:
	position.x += position.x * projectileStats.speed * delta
	
