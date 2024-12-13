extends PotionBase

@onready var animationPlayer = $AnimationPlayer;

func _ready() -> void:
	animationPlayer.play("idle");

func _on_pick_up() -> void:
	PlayerPotions.addPotion(potion);
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		animationPlayer.play("pickUp");
