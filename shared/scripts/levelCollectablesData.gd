extends Node

const FILEPATH = "user://saves/%s_collectables.json"
const COINSPATH = "coins"

func addCoin(levelName: String, coinId: String) -> void:
	var levelFileName = FILEPATH % levelName
	var file = FileAccess.open(levelFileName, FileAccess.WRITE_READ)
	if not file or file.get_length() == 0:
		return;
	var data = JSON.parse_string(file.get_as_text())
	print(data)
	if data == null:
		data = {};
	
	if not data.has(COINSPATH):
		data[COINSPATH] = [];
	
	data[COINSPATH].append(coinId);
	var stringifiedData = JSON.stringify(data);
	file.store_line(stringifiedData)
	file.close();
