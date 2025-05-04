class_name CollectablesEmitter extends Node

signal mithrilPickedUp(amount: int);
signal bookPickedUp(amount: int);

func emitMithrilPickedUp(amount: int) -> void:
  mithrilPickedUp.emit(amount)

func emitBooksPickedUp(amount: int) -> void:
  bookPickedUp.emit(amount)