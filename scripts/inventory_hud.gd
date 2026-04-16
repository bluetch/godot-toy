extends CanvasLayer

@onready var item_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ItemList

func _ready() -> void:
	# 預設為隱藏狀態
	visible = false
	PlayerState.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed()

func _input(event: InputEvent) -> void:
	# 免設定 InputMap，直接監聽鍵盤上的 B 鍵
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		visible = !visible
		if visible:
			_on_inventory_changed() # 確保每次打開都是最新狀態

func _on_inventory_changed() -> void:
	# 清空舊清單
	for child in item_list.get_children():
		child.queue_free()
	
	if PlayerState.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包裡空無一物。"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(empty_label)
		return
	
	# 根據目前擁有的道具建立新清單
	for item_id in PlayerState.inventory:
		if PlayerState.ITEM_DB.has(item_id):
			var item_data = PlayerState.ITEM_DB[item_id]
			
			# 用 Button 作為條目，不僅有點擊反饋，還原生支援 Hover Tooltip
			var btn = Button.new()
			btn.text = item_data["name"]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			# 當滑鼠懸停時顯示道具的敘述
			btn.tooltip_text = item_data["desc"]
			
			# 視覺留白設定
			btn.custom_minimum_size = Vector2(0, 50)
			
			item_list.add_child(btn)
