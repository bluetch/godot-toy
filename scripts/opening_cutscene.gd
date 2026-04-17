extends CanvasLayer

# --- 節點參考 ---
@onready var background: ColorRect = $Background
@onready var dialog_box = $DialogBox

# --- 開場動畫數據 ---
var BEATS: Array = []         # 從 JSON 讀取的每一幕內容
var _current_beat: int = 0    # 目前進行到第幾幕
var _ending: bool = false      # 防止重複觸發結束動畫

func _ready() -> void:
	# 確保初始背景是全黑
	background.color = Color.BLACK
	
	# 下載劇情資料並掛載信號
	_load_beats_from_json()
	
	if dialog_box == null:
		push_error("OpeningCutscene: 找不到 DialogBox 節點！")
		return
	
	# 核心邏輯：監聽通用對話框發出的「一句唸完」信號，自動換下一幕
	dialog_box.dialogue_finished.connect(_on_beat_finished)
	
	# 開始第一段演出
	if BEATS.size() > 0:
		_show_beat(0)

# 解析外部 JSON 檔案
# 這跟網頁開發中 fetch API 後處理 JSON 資料的邏輯非常像
func _load_beats_from_json() -> void:
	var file = FileAccess.open("res://assets/data/opening.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json_data = JSON.parse_string(content)
		if typeof(json_data) == TYPE_ARRAY:
			for item in json_data:
				# 處理顏色格式：如果 JSON 裡存的是十六進制字串，將其轉為 Godot 的 Color 物件
				if item.has("bg") and typeof(item["bg"]) == TYPE_STRING:
					item["bg"] = Color(item["bg"])
				BEATS.append(item)

# 顯示某一幕演出 (展示 Tween 動畫)
func _show_beat(index: int) -> void:
	var beat = BEATS[index]
	
	# --- Tween (補間動畫) ---
	# 類比 CSS 的 transition。我們讓背景顏色在 0.3 秒內平滑改變。
	var tween = create_tween()
	tween.tween_property(background, "color", beat.get("bg", Color.BLACK), 0.3)
	
	# 將當前的演出資料傳給對話框進行打字顯示
	dialog_box.show_dialogue([beat])

# 當對話框打完一句後，如果是開場動畫，我們就切換到下一幕
func _on_beat_finished() -> void:
	_current_beat += 1
	if _current_beat >= BEATS.size():
		# 已經是最後一幕，結束動畫
		_end_cutscene()
	else:
		_show_beat(_current_beat)

# 鍵盤/滑鼠輸入處理
func _input(event: InputEvent) -> void:
	# 跳過開場功能
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_end_cutscene()
		return
		
	# 判斷是否為「有效按鍵（滑鼠或按鈕）」
	if not (event is InputEventKey and event.pressed) and \
	   not (event is InputEventMouseButton and event.pressed):
		return
	
	# 直接叫對話框推進到下一步（或是加速打字機）
	if dialog_box:
		dialog_box.next_line()

# 結束過場動畫，切換到主遊戲場景
func _end_cutscene() -> void:
	if _ending: return
	_ending = true
	
	# 演出最後的黑屏淡出
	var tween = create_tween()
	tween.tween_property(background, "color", Color.BLACK, 1.0)
	
	# 等待動畫完成 (await)，類似 JS 的 Promise / await
	await tween.finished
	
	# 跳轉場景
	get_tree().change_scene_to_file("res://scenes/game.tscn")
