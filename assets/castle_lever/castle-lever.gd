extends StaticBody3D

var active := false

signal active_changed(active: bool)

func activate() -> void:
    active = true
    active_changed.emit(true)