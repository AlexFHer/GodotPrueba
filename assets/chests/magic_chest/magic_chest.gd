extends StaticBody3D

@onready var _forceField: Node3D = $ForceField
@onready var _chest: Node3D = $MagicChestModel

@onready var _chest_animation_tree: AnimationTree = $MagicChestModel/AnimationTree