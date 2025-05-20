extends Node

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree

var current_active_potion: PotionTypes.PotionType = PotionTypes.PotionType.None

func _process(delta: float) -> void:
	# If player attack input is pressed 
	if Input.is_action_just_pressed("attack"):
		_animation_tree.set("parameters/StaffHitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _play_staff_hit_animation() -> void:
	_animation_tree.set("parameters/StaffHitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
