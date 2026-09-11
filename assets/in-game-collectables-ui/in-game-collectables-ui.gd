class_name inGameCollectablesUI extends Control

@export var display_duration := 3.0
@export var entrance_duration := 0.45
@export var baby_taken_texture: Texture2D
@export var baby_not_taken_texture: Texture2D
@onready var content: Control = $Content
@onready var bottom_content: Control = $BottomContent
@onready var mithril_count_label: Label = %MithrilCount
@onready var book_icon: TextureRect = %BookIcon
@onready var key_icon: TextureRect = %KeyIcon
@onready var book_count_label: Label = %BooksCount
@onready var baby_icons: Array[TextureRect] = [%BabyIcon, %BabyIcon2, %BabyIcon3]
@onready var shard_count_label: Label = %ShardsCount
var _animation: Tween

func _ready() -> void:
	PlayerInventory.numberOfKeysChanged.connect(_update_key_icon)
	_update_key_icon(PlayerInventory.keys)
	hide_immediately()

func update_current_collectables(levelCollectables: LevelCollectables) -> void:
	mithril_count_label.text = str(levelCollectables.currentMithrils)
	book_count_label.text = str(levelCollectables.currentBooks)
	for index in baby_icons.size():
		baby_icons[index].texture = baby_taken_texture if index < levelCollectables.currentBabys else baby_not_taken_texture
	shard_count_label.text = str(levelCollectables.currentShards)

func _update_key_icon(numberOfKeys: int) -> void:
	key_icon.visible = numberOfKeys > 0

func show_collectables() -> void:
	if _animation != null:
		_animation.kill()
	if not visible:
		content.position.y = -size.y
		content.modulate.a = 0.0
		bottom_content.position.y = size.y
		bottom_content.modulate.a = 0.0
	show()
	_animation = create_tween()
	_animation.tween_property(content, "position:y", 0.0, entrance_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_animation.parallel().tween_property(content, "modulate:a", 1.0, entrance_duration * 0.6)
	_animation.parallel().tween_property(bottom_content, "position:y", 0.0, entrance_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_animation.parallel().tween_property(bottom_content, "modulate:a", 1.0, entrance_duration * 0.6)
	_animation.tween_interval(display_duration)
	_animation.tween_property(content, "position:y", -60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.parallel().tween_property(content, "modulate:a", 0.0, 0.22)
	_animation.parallel().tween_property(bottom_content, "position:y", 60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.parallel().tween_property(bottom_content, "modulate:a", 0.0, 0.22)
	_animation.tween_callback(hide)

func hide_immediately() -> void:
	if _animation != null:
		_animation.kill()
	hide()
