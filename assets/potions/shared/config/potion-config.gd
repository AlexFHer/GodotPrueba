class_name PotionsConfig

const _potionProperties = {
	PotionTypes.PotionType.Jump: { "lifeTime": 30 },
	PotionTypes.PotionType.Speed: { "lifeTime": 10 },
	PotionTypes.PotionType.Fire: { "lifeTime": 30 }
}

static func get_potion_properties(potionType: PotionTypes.PotionType):
	if potionType in _potionProperties:
		return _potionProperties[potionType]
	else:
		return null
