extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Label

@export var prompt_text: String = "E 調查"
@export var description_lines: Array[String] = [
	"這是一個可互動物件。"
]
@export var interacted_description_lines: Array[String] = [
	"已經調查過了，沒有特別的東西。"
]
@export var obtained_item_id: String = "" # 如果有填寫，代表互動後會獲得該道具/線索
@export var obtained_item_text: String = "你找到了一個東西。"
@export var interacted_texture: Texture2D

var has_interacted := false

func _ready() -> void:
	# 這個腳本只負責互動邏輯；圖片直接在 Sprite2D 節點上設定。
	label.text = prompt_text
	label.visible = false
	# 更新label 置
	label.position.y = sprite_2d.get_rect().size.y / 2.0 + 0

func interact() -> Array[String]:
	if has_interacted:
		return interacted_description_lines

	var lines = description_lines.duplicate()
	if obtained_item_id != "":
		lines.append(obtained_item_text)
		# 未來需要背包系統時，可以在這發射信號：
		# emit_signal("item_found", obtained_item_id)
		print("獲得道具/線索: ", obtained_item_id)
	
	has_interacted = true
	if interacted_texture != null:
		sprite_2d.texture = interacted_texture
		
	return lines

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
