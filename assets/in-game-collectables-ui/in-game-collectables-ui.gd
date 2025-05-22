class_name inGameCollectablesUI extends Control

@onready var mithril_count_label: Label = %MithrilCount
@onready var book_icon: Sprite2D = %BookIcon
@onready var key_icon: Sprite2D = %KeyIcon

func _ready() -> void:
	PlayerInventory.numberOfKeysChanged.connect(_update_key_icon)
	CollectablesEmitterService.bookPickedUp.connect(_on_book_picked_up)
	_update_key_icon(0)
	_on_book_picked_up(0)

func update_current_collectables(levelCollectables: LevelCollectables) -> void:
	update_mithril_count(levelCollectables)

func update_mithril_count(levelCollectables: LevelCollectables) -> void:
	mithril_count_label.text = str(levelCollectables.currentMithrils)

func _update_key_icon(numberOfKeys: int) -> void:
	if numberOfKeys > 0:
		key_icon.visible = true
	else:
		key_icon.visible = false

func _on_book_picked_up(amount: int) -> void:
	if amount > 0:
		book_icon.visible = true
	else:
		book_icon.visible = false
