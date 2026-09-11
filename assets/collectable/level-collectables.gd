extends Resource

class_name LevelCollectables

@export var requiredMithrils := 0;
var currentMithrils := 0;
@export var requiredBooks := 0;
var currentBooks := 0;
@export var requiredBabys := 0
var currentBabys := 0
@export var requiredShards := 0
var currentShards := 0

func is_complete() -> bool:
	var has_collectables := requiredMithrils > 0 or requiredBooks > 0 or requiredBabys > 0 or requiredShards > 0
	return has_collectables and currentMithrils >= requiredMithrils \
		and currentBooks >= requiredBooks \
		and currentBabys >= requiredBabys \
		and currentShards >= requiredShards
