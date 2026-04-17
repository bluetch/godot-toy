extends CanvasLayer

# --- 定義信號 (Signals) ---
# 類比 JavaScript 的 CustomEvent。當對話結束，我們會發出這個信號，讓其他腳本知道。
signal dialogue_finished

# --- 節點參考 (@onready) ---
# 使用 $ 取得節點路徑。這是在「場景樹」載入完成後才會執行的參考賦值。
@onready var dialogue_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Dialogue
@onready var panel: Panel = $Control/Panel
@onready var arrow: Label = $Control/Panel/MarginContainer/Arrow
@onready var speaker_label: Label = $Control/Panel/SpeakerBracket/Margin/Speaker
@onready var speaker_bracket: PanelContainer = $Control/Panel/SpeakerBracket

# --- 對話狀態 ---
var lines: Array = []         # 存放目前整段對話的陣列
var current_line: int = 0     # 追蹤處理到第幾行

var _full_text: String = ""   # 當前這句話的完整內容（打字完成前的全文字）
var _char_index: int = 0      # 記錄目前打到第幾個字
var _is_typing: bool = false  # 打字機狀態鎖定，防止在打字時觸發跳轉
const CHAR_DELAY = 0.04       # 每個字出現的間隔秒數

func _ready() -> void:
	# 初始隱藏整個對話框
	panel.visible = false
	
	# 初始化箭頭 UI (▼) 的位置，讓它靠右下顯示
	# set_anchors_and_offsets_preset 類比 CSS 的定位
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrow.offset_right = -12
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# 【公開函式】讓外部腳本（如 game.gd）啟動對話流
func show_dialogue(dialogue: Array):
	lines = dialogue
	current_line = 0
	panel.visible = true
	_start_typing(lines[current_line])

# 開始處理單一行的顯示與打字
func _start_typing(text_or_dict):
	# 判斷輸入是「純字串」還是「帶說話者的 JSON 字典」
	if typeof(text_or_dict) == TYPE_DICTIONARY:
		var speaker = text_or_dict.get("speaker", "")
		var line = text_or_dict.get("text", "")
		speaker_label.text = speaker
		# 如果名字標籤是空字串，就隱藏整個背景框 (SpeakerBracket)
		speaker_bracket.visible = speaker != "" 
		_full_text = line
	else:
		# 純字串模式（例如：物品描述）
		speaker_bracket.visible = false
		_full_text = str(text_or_dict)

	# 重置打字機指針並開始遞迴
	_char_index = 0
	_is_typing = true
	dialogue_label.text = ""
	arrow.visible = false
	_type_next_char()

# 打字機的核心邏輯：遞迴呼叫
func _type_next_char():
	if not _is_typing:
		return
		
	if _char_index < _full_text.length():
		_char_index += 1
		# String.left(n) 類比 JS 的 slice(0, n)
		dialogue_label.text = _full_text.left(_char_index)
		
		# 使用 Timer 達成非阻塞式的等待
		# CONNECT_ONE_SHOT 類比 JS 的 { once: true }，執行完就移除監聽
		get_tree().create_timer(CHAR_DELAY).timeout.connect(_type_next_char, CONNECT_ONE_SHOT)
	else:
		# 打完了
		_is_typing = false
		arrow.visible = true

# 快進邏輯：如果玩家在打字時按鍵，直接顯示全文
func _finish_typing():
	_is_typing = false
	_char_index = _full_text.length()
	dialogue_label.text = _full_text
	arrow.visible = true

# 【核心功能】外部呼叫來推進對話（例如按 Space 鍵）
func next_line():
	if _is_typing:
		_finish_typing()
		return
		
	current_line += 1
	if current_line >= lines.size():
		# 全部念完了，隱藏並發出結束信號
		hide_dialogue()
	else:
		# 繼續下一句
		_start_typing(lines[current_line])

func hide_dialogue():
	panel.visible = false
	_is_typing = false
	# 發送信號通知所有監聽者（如 game.gd），可以用來恢復角色行動
	dialogue_finished.emit()

# 輔助用：讓外部確認對話框現在是不是正開著
func dialogue_is_visible() -> bool:
	return panel.visible
