class_name PotionMergerService extends Node

const mergePotionsConfig = {
	[PotionTypes.PotionType.Jump, PotionTypes.PotionType.Speed]: PotionTypes.PotionType.JumpAndSpeed,
	[PotionTypes.PotionType.Jump, PotionTypes.PotionType.Fire]: PotionTypes.PotionType.JumpAndFire,
	[PotionTypes.PotionType.Speed, PotionTypes.PotionType.Fire]: PotionTypes.PotionType.SpeedAndFire
}

static var selectedPotionToMerge = PotionTypes.PotionType.None;

static func mergePotions(type1: PotionTypes.PotionType, type2: PotionTypes.PotionType) -> PotionTypes.PotionType:
	var key = [type1, type2]
	if mergePotionsConfig.has(key):
		return mergePotionsConfig[key]
	else:
		return PotionTypes.PotionType.None
