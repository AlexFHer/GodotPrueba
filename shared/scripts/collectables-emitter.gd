class_name CollectablesEmitter extends Node

signal mithrilPickedUp(amount: int);
signal bookPickedUp();

func emitMithrilPickedUp(amount: int) -> void:
  mithrilPickedUp.emit(amount)

func emitBooksPickedUp(amount: int) -> void:
  bookPickedUp.emit(amount)