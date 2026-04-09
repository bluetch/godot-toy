extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var day_label: Label = $DayLabel

# 過場動畫結束、玩家按鍵後發出，通知外部繼續
signal transition_finished

# 是否正在等待玩家按鍵（true 時才監聽按鍵）
var _waiting: bool = false

func _ready() -> void:
	# 預設隱藏，由 start() 觸發
	hide()

# 由外部（player.gd）呼叫，啟動一天結束的過場
func start():
	show()
	# 先把 overlay 設成全透明，等一下用 tween 淡入
	overlay.modulate.a = 0
	day_label.visible = false

	# Tween：在指定時間內平滑改變某個屬性的值
	# 這裡讓 overlay 的 alpha 在 1 秒內從 0 變成 1（畫面漸漸變黑）
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
	# await 等 tween 播完才繼續執行下面的程式碼
	await tween.finished

	# 黑屏後顯示文字，開始等玩家按鍵
	day_label.visible = true
	_waiting = true

# _input 處理所有鍵盤/滑鼠事件
func _input(event: InputEvent) -> void:
	# 只在等待狀態下才回應按鍵
	if _waiting and event is InputEventKey and event.pressed:
		_waiting = false
		transition_finished.emit()
