extends CanvasLayer

@onready var clock_face: Sprite2D = $ClockFace
@onready var hour_hand: Sprite2D = $HourHand
@onready var minute_hand: Sprite2D = $MinuteHand
@onready var snap_sound: AudioStreamPlayer2D = $SnapSound
@onready var hint_button: Button = $HintButton
@onready var snap_hint: ColorRect = $SnapHint

# 修復小遊戲完成時發出，通知 player.gd 繼續流程
signal minigame_completed

# 時鐘中心的畫面座標（在 _ready 計算）
var clock_center: Vector2

# 目前正在被拖動的指針（null 表示沒有）
var dragging: Sprite2D = null

# 兩根指針是否已歸位
var hour_snapped: bool = false
var minute_snapped: bool = false

# 指針距離時鐘中心多近才觸發吸附（pixel）
const SNAP_DISTANCE = 40.0

func _ready():
	# 遊戲開始時不監聽輸入，等 start() 呼叫才開始
	set_process_input(false)
	# 把時鐘放在畫面正中央
	var screen_size = get_viewport().get_visible_rect().size
	clock_center = screen_size / 2
	clock_face.position = clock_center
	# 提示圓圈（顯示吸附位置）預設隱藏
	snap_hint.position = clock_center - Vector2(40, 40)
	snap_hint.hide()
	hide()
	# debug 專用，只有「直接跑這個場景」時才自動 start
	if OS.is_debug_build() and get_parent() == get_tree().root:
		start()
	hint_button.pressed.connect(Callable(self, "_on_hint_button_pressed"))

# 由 player.gd 呼叫，重置並啟動小遊戲
func start():
	set_process_input(true)
	hour_snapped = false
	minute_snapped = false
	dragging = null
	# 把兩根指針隨機放在時鐘周圍
	hour_hand.position = _random_position_around_clock()
	minute_hand.position = _random_position_around_clock()
	show()

# 在時鐘中心周圍隨機找一個位置（距離 150~250px）
func _random_position_around_clock() -> Vector2:
	# TAU = 2π，代表完整一圈的弧度
	var angle = randf() * TAU
	var distance = randf_range(150, 250)
	# 用三角函數把角度轉成 x/y 偏移量
	return clock_center + Vector2(cos(angle), sin(angle)) * distance

func _input(event: InputEvent) -> void:
	# 滑鼠左鍵按下：檢查是否點到指針
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not hour_snapped and _is_clicking_on(hour_hand, event.position):
				dragging = hour_hand
			elif not minute_snapped and _is_clicking_on(minute_hand, event.position):
				dragging = minute_hand
			# 拖動中的指針變色，給玩家視覺回饋
			if dragging != null:
				dragging.modulate = Color(1.5, 1.2, 0.5)
		else:
			# 放開滑鼠：還原顏色，判斷是否觸發吸附
			if dragging != null:
				dragging.modulate = Color(1, 1, 1)
				_check_snap(dragging)
			dragging = null

	# 滑鼠移動：讓被拖動的指針跟著走
	if event is InputEventMouseMotion and dragging != null:
		dragging.position += event.relative

# 判斷點擊位置是否命中指針（45px 容錯範圍）
func _is_clicking_on(hand: Sprite2D, click_pos: Vector2) -> bool:
	return hand.position.distance_to(click_pos) < 45

# 放開指針時判斷是否夠靠近時鐘中心
func _check_snap(hand: Sprite2D) -> void:
	if hand.position.distance_to(clock_center) < SNAP_DISTANCE:
		# 吸附到中心
		hand.position = clock_center
		if hand == hour_hand:
			hour_snapped = true
		else:
			minute_snapped = true
		dragging = null

		# 兩根都歸位，完成修復
		if hour_snapped and minute_snapped:
			snap_sound.play()
			set_process_input(false)
			# 等 1.2 秒讓玩家看清楚結果，再進入下一個流程
			# await 會暫停這個函式，但不會阻塞遊戲（非同步）
			await get_tree().create_timer(1.2).timeout
			hide()
			minigame_completed.emit()

func _on_hint_button_pressed() -> void:
	# 顯示吸附位置提示，只能使用一次
	snap_hint.show()
	hint_button.disabled = true
