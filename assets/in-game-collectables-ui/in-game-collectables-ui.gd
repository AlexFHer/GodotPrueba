class_name inGameCollectablesUI extends Control

@onready var mithril_count_label: Label = %MithrilCount

func update_current_collectables(levelCollectables: LevelCollectables) -> void:
	updateMithrilCount(levelCollectables)

func updateMithrilCount(levelCollectables: LevelCollectables) -> void:
	mithril_count_label.text = str(levelCollectables.currentMithrils) + "/" + str(levelCollectables.requiredMithrils)
