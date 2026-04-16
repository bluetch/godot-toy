extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

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
	# UI Component has been extracted globally.
	pass

func interact() -> Array[String]:
	if has_interacted:
		return interacted_description_lines

	var lines = description_lines.duplicate()
	if obtained_item_id != "":
		# 任務防呆：如果時序未到，阻止玩家提早獲取道具
		if obtained_item_id == "mouth_patch" and PlayerState.state < PlayerState.TutorialState.TOLD_TO_FIND_MOUTH:
			return ["一個生鏽的綠色鐵箱。還沒有理由去翻它。"]
		elif obtained_item_id == "clock_spring" and PlayerState.state < PlayerState.TutorialState.SAW_FROZEN:
			return ["一個滿是灰塵的通風口。"]
			
		# 自動解析道具名稱，告別「你獲得了一個東西」
		if PlayerState.ITEM_DB.has(obtained_item_id):
			var item_name = PlayerState.ITEM_DB[obtained_item_id]["name"]
			lines.append("【系統】妳獲得了重要道具：[" + item_name + "]！")
		else:
			lines.append(obtained_item_text)
			
		print("獲得道具/線索: ", obtained_item_id)
		
		# 加入背包與更新教學狀態機
		PlayerState.add_item(obtained_item_id)
		if obtained_item_id == "mouth_patch":
			PlayerState.state = PlayerState.TutorialState.HAS_MOUTH
		elif obtained_item_id == "clock_spring":
			PlayerState.state = PlayerState.TutorialState.HAS_SPRING
	
	has_interacted = true
	if interacted_texture != null:
		sprite_2d.texture = interacted_texture
		
	return lines

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_object = self

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 只在玩家目前鎖定的是自己時才清空，避免蓋掉別的互動物件。
		if body.near_object == self:
			body.near_object = null
