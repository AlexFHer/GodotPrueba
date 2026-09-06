extends SceneTree

class DamageBody extends StaticBody3D:
	var hits: int = 0
	func get_hit() -> void:
		hits += 1

class DamageArea extends Area3D:
	var hits: int = 0
	func get_hit() -> void:
		hits += 1

var effects: Array[Node] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _physics_steps() -> void:
	for index in range(4):
		await physics_frame
	await process_frame

func _add_shape(target: CollisionObject3D) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.7, 0.5)
	shape.shape = box
	target.add_child(shape)

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	stage.child_entered_tree.connect(func(node: Node) -> void:
		if node.get_script() == load("res://player/particles/staff_impact.gd"):
			effects.append(node))
	var player = load("res://player/player.tscn").instantiate()
	stage.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	for child in player.find_children("*", "", true, false):
		child.set_process(false)
		child.set_physics_process(false)
		if child is AnimationTree:
			child.active = false
	var combat = player.get_node("Managers/CombatSystem")
	var collision: CollisionShape3D = player.get_node("Rig/StaffArea3D/StaffCollision")
	await _physics_steps()
	var origin := collision.global_position
	var wall := StaticBody3D.new()
	_add_shape(wall)
	stage.add_child(wall)
	wall.global_position = origin + Vector3(0.4, 0, 0)
	await _physics_steps()
	_check(effects.is_empty(), "Idle overlap spawned an impact")
	combat._normal_attack_active = true
	collision.disabled = false
	await _physics_steps()
	_check(effects.size() == 1, "World collider must emit exactly one impact")
	if effects.size() == 1:
		_check(effects[0].global_position.distance_to(origin) > 0.05, "Impact fell back to staff center instead of contact")
	combat._damage_node_with_staff(wall)
	combat._damage_current_staff_overlaps_after_physics(combat._attack_generation)
	await _physics_steps()
	_check(effects.size() == 1, "Repeated overlaps duplicated feedback")
	wall.queue_free()
	await _physics_steps()
	var body := DamageBody.new()
	body.collision_layer = 4
	body.add_to_group("CanGetHit")
	_add_shape(body)
	stage.add_child(body)
	body.global_position = origin
	await _physics_steps()
	_check(effects.size() == 2 and body.hits == 1, "Enemy layer contact must emit and damage once")
	combat._damage_node_with_staff(body)
	_check(effects.size() == 2 and body.hits == 1, "Damage or feedback repeated during same swing")
	combat._impact_targets_this_swing.clear()
	combat._damaged_targets_this_swing.clear()
	combat._damage_current_staff_overlaps_after_physics(combat._attack_generation)
	await _physics_steps()
	_check(effects.size() == 3 and body.hits == 2, "Next swing must hit existing overlap again")
	body.queue_free()
	await _physics_steps()
	var area := DamageArea.new()
	area.add_to_group("CanGetHit")
	_add_shape(area)
	stage.add_child(area)
	area.global_position = origin
	await _physics_steps()
	_check(effects.size() == 4 and area.hits == 1, "Damageable area must emit feedback")
	combat._damage_node_with_staff(player)
	combat._damage_node_with_staff(player.get_node("AbilityDamageArea"))
	_check(effects.size() == 4, "Player colliders emitted feedback")
	var trigger := Area3D.new()
	_add_shape(trigger)
	stage.add_child(trigger)
	trigger.global_position = origin
	await _physics_steps()
	_check(effects.size() == 4, "Detection trigger emitted feedback")
	combat._normal_attack_active = false
	combat._impact_targets_this_swing.clear()
	combat._damage_node_with_staff(area)
	_check(effects.size() == 4, "Inactive attack emitted feedback")
	await create_timer(0.9).timeout
	for effect in effects:
		_check(not is_instance_valid(effect), "Impact did not clean itself up")
	print("STAFF IMPACT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	stage.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
