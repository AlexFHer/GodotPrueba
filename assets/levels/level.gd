extends Node3D

@onready var inGameCollectablesUiControl: inGameCollectablesUI = %InGameCollectablesUI

@export var levelCollectables: LevelCollectables;
@export var levelName := ''

func _ready() -> void:
	# Connect signals to the collectables emitter
	CollectablesEmitterService.mithrilPickedUp.connect(_on_mithril_picked_up)
	CollectablesEmitterService.bookPickedUp.connect(_on_book_picked_up)
	inGameCollectablesUiControl.update_current_collectables(levelCollectables)
	_hide_collectables_ui()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle-hud"):
		_show_collectables_ui()

func _on_mithril_picked_up(amount: int) -> void:
	levelCollectables.currentMithrils += amount
	inGameCollectablesUiControl.update_current_collectables(levelCollectables)

func _on_book_picked_up(amount: int) -> void:
	levelCollectables.currentBooks += amount
	inGameCollectablesUiControl.update_current_collectables(levelCollectables)

func _show_collectables_ui() -> void:
	inGameCollectablesUiControl.visible = true
	get_tree().create_timer(3).timeout.connect(_hide_collectables_ui)

func _hide_collectables_ui() -> void:
	inGameCollectablesUiControl.visible = false