extends Node3D

@onready var inGameCollectablesUiControl: inGameCollectablesUI = %InGameCollectablesUI

@export var levelCollectables: LevelCollectables;
@export var levelName := ''

func _ready() -> void:
  # Connect signals to the collectables emitter
  CollectablesEmitterService.mithrilPickedUp.connect(_on_mithril_picked_up)
  CollectablesEmitterService.bookPickedUp.connect(_on_book_picked_up)
  inGameCollectablesUiControl.update_current_collectables(levelCollectables)


func _on_mithril_picked_up(amount: int) -> void:
  print("Picked up mithril: " + str(amount))
  levelCollectables.currentMithrils += amount
  inGameCollectablesUiControl.update_current_collectables(levelCollectables)

func _on_book_picked_up() -> void:
  levelCollectables.currentBooks += 1
  inGameCollectablesUiControl.update_current_collectables(levelCollectables)