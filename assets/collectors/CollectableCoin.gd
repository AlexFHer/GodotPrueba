extends Area3D

var target: Node3D;
var elapsed = 0.0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target != null:
		checkTarget(delta);
	pass

func checkTarget(delta: float) -> void:
	if target == null:
		pass

	position = lerp(position, target.position, 0.3)
	elapsed += delta

func _on_object_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		queue_free();
		GlobalManager.mithrilCoins += 1;
		print(GlobalManager.mithrilCoins);
		pass # Replace with function body.


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		target = body;
