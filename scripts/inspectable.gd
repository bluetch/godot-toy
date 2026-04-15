extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Label

@export var prompt_text: String = "E 調查"
@export var description_lines: Array[String] = [
	"紙箱堆得很高，最上面那個像是最近被翻過。"
]
@export var opened_texture: Texture2D

var is_opened := false

func _ready() -> void:
	# 這個腳本只負責互動邏輯；圖片直接在 Sprite2D 節點上設定。
	label.text = prompt_text
	label.visible = false
	# 更新label 置
	label.position.y = sprite_2d.get_rect().size.y / 2.0 + 0

func open() -> void:
	if is_opened:
		return

	if opened_texture == null:
		return

	sprite_2d.texture = opened_texture
	is_opened = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = true
		body.near_object = self

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = false
		# 只在玩家目前鎖定的是自己時才清空，避免蓋掉別的互動物件。
		if body.near_object == self:
			body.near_object = null
