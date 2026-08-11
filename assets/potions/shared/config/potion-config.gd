class_name PotionsConfig

const _potionProperties = {
	PotionTypes.PotionType.Jump: { "lifeTime": 30 },
	PotionTypes.PotionType.Speed: { "lifeTime": 20 },
	PotionTypes.PotionType.Fire: { "lifeTime": 30 },
	PotionTypes.PotionType.JumpAndSpeed: { "lifeTime": 30 },
	PotionTypes.PotionType.JumpAndFire: { "lifeTime": 30 },
	PotionTypes.PotionType.SpeedAndFire: { "lifeTime": 30 }
}

const _potionColors = {
	PotionTypes.PotionType.Fire: Color(1.0, 0.12, 0.05),
	PotionTypes.PotionType.Jump: Color(0.2, 0.45, 1.0),
	PotionTypes.PotionType.Speed: Color(0.15, 1.0, 0.25),
	PotionTypes.PotionType.JumpAndFire: Color(0.85, 0.18, 1.0),
	PotionTypes.PotionType.JumpAndSpeed: Color(0.0, 0.95, 1.0),
	PotionTypes.PotionType.SpeedAndFire: Color(1.0, 0.55, 0.0)
}

static func get_potion_properties(potionType: PotionTypes.PotionType):
	if potionType in _potionProperties:
		return _potionProperties[potionType]
	else:
		return null


static func get_potion_color(potionType: PotionTypes.PotionType) -> Color:
	return _potionColors.get(potionType, Color.WHITE)
