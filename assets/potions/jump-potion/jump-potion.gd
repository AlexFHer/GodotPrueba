extends PotionBase

@export var potionPickupAudio: AudioStreamPlayer3D;

@onready var potionCollision: CollisionShape3D = %PotionCollision;
@onready var potionModel: Node3D = %Model;

func _on_pick_up() -> void:
	PlayerPotions.addPotion(potionType);
	_remove_collision()
	_remove_model()
	potionPickupAudio.play()
	await potionPickupAudio.finished
	queue_free()


func _on_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		_on_pick_up()

func _remove_collision() -> void:
	potionCollision.disabled = true

func _remove_model() -> void:
	potionModel.queue_free()
