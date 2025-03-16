extends Control

var mithril := 0;
@onready var mithril_count_label: Label = %MithrilCount

# TODO: Cambiar esto para que no se gestione aqui el numero de mithrills
func _ready() -> void:
	#_set_visible(false);
	CollectablesEmitterService.mithrilPickedUp.connect(_on_mithril_pickUp)

func _on_mithril_pickUp() -> void:
	mithril += 1;
	mithril_count_label.text = str(mithril)

func _set_visible(newVisible: bool) -> void:
	visible = newVisible;
