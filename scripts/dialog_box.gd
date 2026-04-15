extends CanvasLayer

# signal 是 Godot 的事件系統
# 這裡定義一個「對話結束」的事件，讓外部（player.gd）可以監聽
# 類比 JavaScript 的 EventEmitter 或 CustomEvent
signal dialogue_finished

# @onready 代表「場景載入完成後才取得這個節點的參考」
# $ 是 get_node() 的縮寫，路徑對應 Scene 面板的節點樹結構
@onready var label: Label = $Control/Panel/MarginContainer/VBoxContainer/Label
@onready var panel: Panel = $Control/Panel
@onready var arrow: Label = $Control/Panel/MarginContainer/Arrow

# 目前這段對話的所有句子（Array）
var lines: Array = []
# 目前顯示到第幾句（index）
var current_line: int = 0

# 底線開頭的變數是 private 的慣例（GDScript 沒有強制，只是命名約定）
var _full_text: String = ""   # 這句話的完整內容
var _char_index: int = 0      # 目前打到第幾個字
var _is_typing: bool = false  # 是否還在打字中
const CHAR_DELAY = 0.04       # 每個字之間的間隔秒數（const = 不會變動的常數）

# _ready() 是 Godot 的生命週期函式，場景載入完成時自動呼叫
# 類比 JavaScript 的 DOMContentLoaded 或 componentDidMount
func _ready() -> void:
	panel.visible = false
	# 以下用程式碼設定 arrow 的 UI 定位
	# PRESET_FULL_RECT = 撐滿父節點（類比 CSS width:100% height:100%）
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# offset_right 負數 = 右邊界往內縮（騰出空間，類比 padding-right）
	arrow.offset_right = -12
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT  # 類比 text-align: right
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER     # 類比 align-items: center

# 公開函式，由外部（player.gd）呼叫來啟動一段對話
func show_dialogue(dialogue: Array):
	lines = dialogue
	current_line = 0
	panel.visible = true
	_start_typing(lines[current_line])

# 開始打一句新的話，重置打字機狀態
func _start_typing(text: String):
	_full_text = text
	_char_index = 0
	_is_typing = true
	label.text = ""
	arrow.visible = false
	_type_next_char()

# 遞迴函式：每次被呼叫就多顯示一個字，然後設定 timer 再呼叫自己
# CONNECT_ONE_SHOT = timer 觸發一次後自動斷開連接（避免重複觸發）
func _type_next_char():
	if not _is_typing:
		return
	if _char_index < _full_text.length():
		_char_index += 1
		# String.left(n) = 取字串前 n 個字元
		label.text = _full_text.left(_char_index)
		get_tree().create_timer(CHAR_DELAY).timeout.connect(_type_next_char, CONNECT_ONE_SHOT)
	else:
		# 所有字都打完了，顯示 ▼ 提示可以繼續
		_is_typing = false
		arrow.visible = true

# 快進：強制顯示完整文字，跳過打字動畫
func _finish_typing():
	_is_typing = false
	_char_index = _full_text.length()
	label.text = _full_text
	arrow.visible = true

# 由外部呼叫，處理「按 E」的邏輯
func next_line():
	# 還在打字中 → 快進到完整文字，不跳下一句
	if _is_typing:
		_finish_typing()
		return
	# 已打完 → 前進到下一句
	current_line += 1
	if current_line >= lines.size():
		# 沒有下一句了，結束對話
		hide_dialogue()
	else:
		_start_typing(lines[current_line])

func hide_dialogue():
	panel.visible = false
	_is_typing = false
	# emit() = 發出這個 signal，通知所有監聽者（player.gd 會收到）
	dialogue_finished.emit()

# 給外部查詢用：對話框目前是否顯示中
func dialogue_is_visible() -> bool:
	return panel.visible
