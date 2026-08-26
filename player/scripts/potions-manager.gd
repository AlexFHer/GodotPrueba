extends Node

signal potion_drink_started(uses_left_slot: bool, uses_right_slot: bool)
signal potion_drink_finished

@onready var _animation_tree: AnimationTree = %PlayerAnimationTree
@onready var _drink_animation_node := (
	(_animation_tree.tree_root as AnimationNodeBlendTree).get_node(&"drink")
	as AnimationNodeAnimation
)
@onready var potmaSounds: PotmaSounds = %PotmaSounds
@onready var _active_potion_service = get_node("/root/ActivePotionEffectService")
@onready var _player := owner as MainPlayer
@export var _potion_particles_system: PotionsParticleSystem;

const MERGE_DECISION_WINDOW_SECONDS := 0.25
const DRINK_LEFT_ANIMATION := &"Potma_DrinkLeft"
const DRINK_RIGHT_ANIMATION := &"Potma_DrinkRight"
const DRINK_BOTH_ANIMATION := &"Potma_DrinkBoth"
const DRINK_ANIMATION_START_GRACE_FRAMES := 3

var _pending_left_drink := false
var _pending_right_drink := false
var _is_waiting_merge_decision := false
var _decision_window_id := 0
var _active_drink_animation: StringName = &""
var _drink_one_shot_was_active := false
var _drink_animation_start_grace_frames := 0

func _ready() -> void:
	_animation_tree.animation_finished.connect(_on_animation_tree_animation_finished)

func _process(_delta: float) -> void:
	_update_drink_animation_state()

	if _is_gameplay_input_locked():
		_cancel_pending_drink_intents()
		return

	if Input.is_action_just_pressed("toggleLeftPotion"):
		PlayerPotions.toggleLeftPotion()

	if Input.is_action_just_pressed("toggleRightPotion"):
		PlayerPotions.toggleRightPotion()

	var l2_just := Input.is_action_just_pressed("drinkPotionLeft")
	var r2_just := Input.is_action_just_pressed("drinkPotionRight")

	if l2_just:
		_register_drink_intent(true)

	if r2_just:
		_register_drink_intent(false)

func _register_drink_intent(isLeft: bool) -> void:
	if _is_gameplay_input_locked():
		return
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
	if _is_gameplay_input_locked():
		_cancel_pending_drink_intents()
		return

	_is_waiting_merge_decision = false
	_resolve_pending_drink()

func _resolve_as_merge() -> void:
	if _is_gameplay_input_locked():
		_cancel_pending_drink_intents()
		return
	_pending_left_drink = false
	_pending_right_drink = false
	_is_waiting_merge_decision = false
	_decision_window_id += 1
	tryMergePotions()

func _resolve_pending_drink() -> void:
	if _is_gameplay_input_locked():
		_cancel_pending_drink_intents()
		return
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
	if _is_gameplay_input_locked():
		return
	var potion_type := PlayerPotions.selectedLeftPotionType
	if potion_type == PotionTypes.PotionType.None:
		return
	if not PlayerPotions.isThereAnyPotionOfType(potion_type):
		return
	if _active_potion_service.has_active_potion():
		return
	potion_drink_started.emit(true, false)
	PlayerPotions.useLeftPotion()
	play_drink_animation(DRINK_LEFT_ANIMATION)

func drinkRightPotion() -> void:
	if _is_gameplay_input_locked():
		return
	var potion_type := PlayerPotions.selectedRightPotionType
	if potion_type == PotionTypes.PotionType.None:
		return
	if not PlayerPotions.isThereAnyPotionOfType(potion_type):
		return
	if _active_potion_service.has_active_potion():
		return
	potion_drink_started.emit(false, true)
	PlayerPotions.useRightPotion()
	play_drink_animation(DRINK_RIGHT_ANIMATION)

func tryMergePotions() -> bool:
	if _is_gameplay_input_locked():
		return false
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

	potion_drink_started.emit(true, true)
	if not PlayerPotions.useMergedPotion(mergedType, [leftType, rightType]):
		potion_drink_finished.emit()
		return false

	play_drink_animation(DRINK_BOTH_ANIMATION)
	return true

func _on_drink_animation_finished() -> void:
	potmaSounds.drinkSoundAudioStream.play()
	_potion_particles_system._play_particles(_active_potion_service.current_active_potion)

func play_drink_animation(animation_name: StringName) -> void:
	_active_drink_animation = animation_name
	_drink_one_shot_was_active = false
	_drink_animation_start_grace_frames = DRINK_ANIMATION_START_GRACE_FRAMES
	_drink_animation_node.animation = animation_name
	_animation_tree.set("parameters/DrinkOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_animation_tree_animation_finished(animation_name: StringName) -> void:
	if animation_name != _active_drink_animation:
		return

	_finish_active_drink_animation(true)

func _update_drink_animation_state() -> void:
	if _active_drink_animation.is_empty():
		return

	var is_one_shot_active := bool(_animation_tree.get("parameters/DrinkOneShot/active"))
	if is_one_shot_active:
		_drink_one_shot_was_active = true
		return

	if _drink_one_shot_was_active:
		_finish_active_drink_animation(true)
		return

	_drink_animation_start_grace_frames -= 1
	if _drink_animation_start_grace_frames <= 0:
		_finish_active_drink_animation(false)

func _finish_active_drink_animation(play_feedback: bool) -> void:
	if _active_drink_animation.is_empty():
		return

	if not play_feedback:
		_animation_tree.set(
			"parameters/DrinkOneShot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)

	_active_drink_animation = &""
	_drink_one_shot_was_active = false
	_drink_animation_start_grace_frames = 0
	potion_drink_finished.emit()
	if play_feedback:
		_on_drink_animation_finished()

func _cancel_pending_drink_intents() -> void:
	if not _pending_left_drink and not _pending_right_drink and not _is_waiting_merge_decision:
		return

	_pending_left_drink = false
	_pending_right_drink = false
	_is_waiting_merge_decision = false
	_decision_window_id += 1


func _is_gameplay_input_locked() -> bool:
	return _player != null and _player.is_gameplay_input_locked()
