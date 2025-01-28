extends Node

const SAVE_PATH = "user://%s"
const SAVE_FOLDER_NAME = "saves"

func _init() -> void:
	createSaveFolder()

func createSaveFolder():
	const directoryPath = SAVE_PATH % SAVE_FOLDER_NAME
	var dir = DirAccess.open(directoryPath)
	if dir == null:
		dir = DirAccess.make_dir_recursive_absolute(directoryPath)
		if dir == OK:
			print("Carpeta creada exitosamente: ", directoryPath)
		else:
			print("Error al crear la carpeta: ", directoryPath)
