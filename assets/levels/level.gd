extends Node3D

@onready var inGameCollectablesUiControl: inGameCollectablesUI = %InGameCollectablesUI

@export var levelCollectables: LevelCollectables;
@export var levelName := ''
var collectable_scope: Node

func _enter_tree() -> void:
	collectable_scope = owner if owner != null else self
	if levelName.is_empty():
		levelName = collectable_scope.scene_file_path
	add_to_group("collectable_levels")

func _ready() -> void:
	# The Resource is authored configuration; this copy is a HUD snapshot.
	levelCollectables = levelCollectables.duplicate() if levelCollectables != null else LevelCollectables.new()
	# Connect signals to the collectables emitter
	CollectablesEmitterService.mithrilPickedUp.connect(_on_mithril_picked_up)
	CollectablesEmitterService.bookPickedUp.connect(_on_collectable_picked_up)
	CollectablesEmitterService.babyPickedUp.connect(_on_collectable_picked_up)
	CollectablesEmitterService.shardPickedUp.connect(_on_collectable_picked_up)
	_refresh_progress()
	inGameCollectablesUiControl.hide_immediately()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle-hud"):
		_show_collectables_ui()

func _on_mithril_picked_up(pickedLevel: String, _amount: int) -> void:
	if pickedLevel == levelName:
		_refresh_progress()

func _on_collectable_picked_up(pickedLevel: String, _amount: int) -> void:
	if pickedLevel == levelName:
		_refresh_progress()

func _refresh_progress() -> void:
	levelCollectables.currentMithrils = LevelCollectablesData.get_total(levelName, "mithril")
	levelCollectables.currentBooks = LevelCollectablesData.get_total(levelName, "book")
	levelCollectables.currentBabys = LevelCollectablesData.get_total(levelName, "baby")
	levelCollectables.currentShards = LevelCollectablesData.get_total(levelName, "shard")
	inGameCollectablesUiControl.update_current_collectables(levelCollectables)

func _show_collectables_ui() -> void:
	inGameCollectablesUiControl.show_collectables()
