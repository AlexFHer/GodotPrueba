extends Node

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var _drink_animation_node := (
	(_animation_tree.tree_root as AnimationNodeBlendTree).get_node(&"drink")
	as AnimationNodeAnimation
)
@onready var potmaSounds: PotmaSounds = %PotmaSounds
@onready var _active_potion_service = get_node("/root/ActivePotionEffectService")
@export var _potion_particles_system: PotionsParticleSystem;

const MERGE_DECISION_WINDOW_SECONDS := 0.25
const DRINK_LEFT_ANIMATION := &"Potma_DrinkLeft"
const DRINK_RIGHT_ANIMATION := &"Potma_DrinkRight"
const DRINK_BOTH_ANIMATION := &"Potma_DrinkBoth"

var _pending_left_drink := false
var _pending_right_drink := false
var _is_waiting_merge_decision := false
var _decision_window_id := 0

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggleLeftPotion"):
		PlayerPotions.toggleLeftPotion()

	if Input.is_action_just_pressed("toggleRightPotion"):
		PlayerPotions.toggleRightPotion()

	if _is_dialogue_consuming_gameplay_input():
		return

	var l2_just := Input.is_action_just_pressed("drinkPotionLeft")
	var r2_just := Input.is_action_just_pressed("drinkPotionRight")

	if l2_just:
		_register_drink_intent(true)

	if r2_just:
		_register_drink_intent(false)

func _register_drink_intent(isLeft: bool) -> void:
	if isLeft:
		_pending_left_drink = true
	else:
		_pending_right_drink = true

	if _pending_left_drink and _pending_right_drink:
		_resolve_as_merge()
		return

	if _is_waiting_merge_decision:
		return

	_start_merge_decision_window()

func _start_merge_decision_window() -> void:
	_is_waiting_merge_decision = true
	_decision_window_id += 1
	var current_window_id = _decision_window_id
	await get_tree().create_timer(MERGE_DECISION_WINDOW_SECONDS, false).timeout

	if current_window_id != _decision_window_id:
		return

	_is_waiting_merge_decision = false
	_resolve_pending_drink()

func _resolve_as_merge() -> void:
	_pending_left_drink = false
	_pending_right_drink = false
	_is_waiting_merge_decision = false
	_decision_window_id += 1
	tryMergePotions()

func _resolve_pending_drink() -> void:
	if _pending_left_drink and _pending_right_drink:
		_resolve_as_merge()
		return

	if _pending_left_drink:
		_pending_left_drink = false
		drinkLeftPotion()

	if _pending_right_drink:
		_pending_right_drink = false
		drinkRightPotion()

func drinkLeftPotion() -> void:
	if PlayerPotions.selectedLeftPotionType == PotionTypes.PotionType.None:
		return
	if _active_potion_service.has_active_potion():
		return
	PlayerPotions.useLeftPotion()
	play_drink_animation(DRINK_LEFT_ANIMATION)

func drinkRightPotion() -> void:
	if PlayerPotions.selectedRightPotionType == PotionTypes.PotionType.None:
		return
	if _active_potion_service.has_active_potion():
		return
	PlayerPotions.useRightPotion()
	play_drink_animation(DRINK_RIGHT_ANIMATION)

func tryMergePotions() -> bool:
	if _active_potion_service.has_active_potion():
		return false

	var leftType = PlayerPotions.selectedLeftPotionType
	var rightType = PlayerPotions.selectedRightPotionType

	if leftType == PotionTypes.PotionType.None or rightType == PotionTypes.PotionType.None:
		return false

	var mergedType = PotionMergerService.mergePotions(leftType, rightType)
	if mergedType == PotionTypes.PotionType.None:
		mergedType = PotionMergerService.mergePotions(rightType, leftType)
	if mergedType == PotionTypes.PotionType.None:
		return false

	if not PlayerPotions.useMergedPotion(mergedType, [leftType, rightType]):
		return false

	play_drink_animation(DRINK_BOTH_ANIMATION)
	return true

func _on_drink_animation_finished() -> void:
	potmaSounds.drinkSoundAudioStream.play()
	_potion_particles_system._play_particles(_active_potion_service.current_active_potion)

func play_drink_animation(animation_name: StringName) -> void:
	_drink_animation_node.animation = animation_name
	_animation_tree.set("parameters/DrinkOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _is_dialogue_consuming_gameplay_input() -> bool:
	var dialogue_controller := get_tree().get_first_node_in_group("dialogue_controller")
	if dialogue_controller == null or not dialogue_controller.has_method("is_consuming_gameplay_input"):
		return false
	return dialogue_controller.call("is_consuming_gameplay_input")
