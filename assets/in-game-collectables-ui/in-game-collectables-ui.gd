class_name inGameCollectablesUI extends Control

@onready var mithril_count_label: Label = %MithrilCount
@onready var book_count_label: Label = %BooksCount
@onready var key_icon: Sprite2D = %KeyIcon

func _ready() -> void:
	PlayerInventory.numberOfKeysChanged.connect(_update_key_icon)
	_update_key_icon(0)

func update_current_collectables(levelCollectables: LevelCollectables) -> void:
	update_mithril_count(levelCollectables)
	update_book_count(levelCollectables)

func update_mithril_count(levelCollectables: LevelCollectables) -> void:
	mithril_count_label.text = str(levelCollectables.currentMithrils) + "/" + str(levelCollectables.requiredMithrils)

func update_book_count(levelCollectables: LevelCollectables) -> void:
	book_count_label.text = str(levelCollectables.currentBooks) + "/" + str(levelCollectables.requiredBooks)

func _update_key_icon(numberOfKeys: int) -> void:
	if numberOfKeys > 0:
		key_icon.visible = true
	else:
		key_icon.visible = false