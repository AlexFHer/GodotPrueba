class_name inGameCollectablesUI extends Control

@onready var mithril_count_label: Label = %MithrilCount
@onready var book_count_label: Label = %BooksCount

func update_current_collectables(levelCollectables: LevelCollectables) -> void:
	update_mithril_count(levelCollectables)
	update_book_count(levelCollectables)

func update_mithril_count(levelCollectables: LevelCollectables) -> void:
	mithril_count_label.text = str(levelCollectables.currentMithrils) + "/" + str(levelCollectables.requiredMithrils)

func update_book_count(levelCollectables: LevelCollectables) -> void:
	book_count_label.text = str(levelCollectables.currentBooks) + "/" + str(levelCollectables.requiredBooks)
