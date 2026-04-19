extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var inspectable_id: String = "" # 如果填寫此 ID，則會從 JSON 載入台詞
@export var description_lines: Array[String] = []
@export var interacted_description_lines: Array[String] = []
@export var obtained_item_id: String = "" # 如果有填寫，代表互動後會獲得該道具/線索
@export var obtained_item_text: String = "" # 優先從 JSON 載入，若無則以此為準
@export var interacted_texture: Texture2D

var has_interacted := false

func interact() -> Array[String]:
	var current_id = inspectable_id
	print("[Debug] 觸發互動. ID: ", current_id if current_id != "" else "無ID")
	
	# 1. 準備回傳陣列
	var final_lines: Array[String] = []
	
	# 2. 載入基礎描述與已互動描述 (如果 JSON 有的話)
	if current_id != "":
		var json_desc = PlayerState.get_inspectable_lines(current_id, "desc")
		if not json_desc.is_empty():
			final_lines = json_desc
			
	# 如果 JSON 沒東西或是沒填 ID，就回退到編輯器原本填的 (backward compatibility)
	if final_lines.is_empty():
		final_lines = description_lines.duplicate()
		
	# 如果連編輯器都沒填，則套用系統預設
	if final_lines.is_empty():
		final_lines = PlayerState.get_system_lines("default_desc")

	# 3. 處理已互動狀態
	if has_interacted:
		var json_interacted = PlayerState.get_inspectable_lines(current_id, "interacted")
		if not json_interacted.is_empty():
			return json_interacted
		
		# 回退到編輯器填寫
		if not interacted_description_lines.is_empty():
			return interacted_description_lines
			
		# 最後回退到系統預設
		return PlayerState.get_system_lines("default_interacted")

	# 4. 處理道具獲取邏輯
	if obtained_item_id != "":
		# 檢查鎖定狀態 (這裡的 ID 是寫死的邏輯 ID)
		var is_locked = false
		if obtained_item_id == "mouth_patch" and PlayerState.state < PlayerState.TutorialState.TOLD_TO_FIND_MOUTH:
			is_locked = true
		elif obtained_item_id == "clock_spring" and PlayerState.state < PlayerState.TutorialState.SAW_FROZEN:
			is_locked = true
			
		if is_locked:
			var locked_lines = PlayerState.get_inspectable_lines(current_id, "not_ready")
			if locked_lines.is_empty():
				locked_lines = PlayerState.get_system_lines("not_ready_generic")
			print("[Debug] 物件鎖定中，顯示鎖定對白。")
			return locked_lines
			
		# 決定「獲得道具」的那句台詞
		var obtained_text = ""
		var json_obtained = PlayerState.get_inspectable_text(current_id, "obtained")
		
		# 優先級：
		# A. JSON 專屬台詞
		if json_obtained != "":
			obtained_text = json_obtained
		# B. JSON 全域模板 + 道具名稱
		elif PlayerState.has_item_data(obtained_item_id):
			var item_name = PlayerState.get_item_name(obtained_item_id)
			var template = PlayerState.get_system_text("default_obtained_template")
			if template != "" and item_name != "":
				obtained_text = template.replace("{item_name}", item_name)
		
		# C. 編輯器台詞 (如果有填的話)
		if obtained_text == "":
			obtained_text = obtained_item_text
			
		# D. 系統預設台詞 (最後的最後)
		if obtained_text == "":
			obtained_text = PlayerState.get_system_text("default_obtained")
			
		if obtained_text != "":
			final_lines.append(obtained_text)
			
		# 更新背包與狀態
		PlayerState.add_item(obtained_item_id)
		if obtained_item_id == "mouth_patch":
			PlayerState.state = PlayerState.TutorialState.HAS_MOUTH
		elif obtained_item_id == "clock_spring":
			PlayerState.state = PlayerState.TutorialState.HAS_SPRING
			
		print("[Debug] 成功獲得道具: ", obtained_item_id)

	# 5. 完成互動，更新表現
	has_interacted = true
	if interacted_texture != null:
		sprite_2d.texture = interacted_texture
		
	print("[Debug] 最終輸出對白數: ", final_lines.size())
	return final_lines

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_object = self

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 只在玩家目前鎖定的是自己時才清空，避免蓋掉別的互動物件。
		if body.near_object == self:
			body.near_object = null
