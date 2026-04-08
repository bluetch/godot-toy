extends CanvasLayer

@onready var clock_face: Sprite2D = $ClockFace
@onready var hour_hand: Sprite2D = $HourHand
@onready var minute_hand: Sprite2D = $MinuteHand
@onready var snap_sound: AudioStreamPlayer2D = $SnapSound
@onready var hint_button: Button = $HintButton
@onready var snap_hint: ColorRect = $SnapHint


signal minigame_completed

# 鐘中心的畫面座標，之後再ready設定
var clock_center: Vector2

var dragging: Sprite2D = null

var hour_snapped: bool = false
var minute_snapped: bool = false

# 指針拖到距離時鐘中心多近才觸發吸附 (pixel)
const SNAP_DISTANCE = 40.0

func _ready():
	# 停止監聽
	set_process_input(false)
	# 時鐘放在畫面中心
	var screen_size = get_viewport().get_visible_rect().size
	clock_center = screen_size / 2
	clock_face.position = clock_center
	# 提示圓圈放在時鐘中心，預設為隱藏
	snap_hint.position = clock_center - Vector2(40, 40)
	snap_hint.hide()
	hide()
	hint_button.pressed.connect(Callable(self, "_on_hint_button_pressed"))
	
func start():
	# 開始監聽
	set_process_input(true)
	# reset
	hour_snapped = false
	minute_snapped = false
	dragging = null
	
	# 指針放到隨機位置 (在時鐘周圍，但不太近)
	hour_hand.position = _random_position_around_clock()
	minute_hand.position = _random_position_around_clock()
	
	show()
	
func _random_position_around_clock() -> Vector2:
	# 在時鐘中心附近隨機找一個點，距離150~250px
	var angle = randf() * TAU # TAU = 2π，代表完整一圈
	var distance = randf_range(150, 250)
	return clock_center + Vector2(cos(angle), sin(angle)) * distance
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not hint_button.disabled and hint_button.get_global_rect().has_point(event.position):
			_on_hint_button_pressed()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			#檢查點到哪跟指針
			if not hour_snapped and _is_clicking_on(hour_hand, event.position):
				dragging = hour_hand
			elif not minute_snapped and _is_clicking_on(minute_hand, event.position):
				dragging = minute_hand
			# 抓到指針時變色
			if dragging != null:
				dragging.modulate = Color(1.5, 1.2, 0.5)
		else:
			# 放開：還原顏色，判斷吸附、清除dragging
			if dragging != null:
				dragging.modulate = Color(1, 1, 1)
				_check_snap(dragging)
			dragging = null
	
	# 滑鼠移動時，被拖動的指針跟著走	
	if event is InputEventMouseMotion and dragging != null:
		dragging.position += event.relative
		
func _is_clicking_on(hand: Sprite2D, click_pos: Vector2) -> bool:
	# 點擊位置距離指針中心30px內算點到
	return hand.position.distance_to(click_pos) < 30
	
func _check_snap(hand: Sprite2D) -> void:
	# 指針夠叫嗯時鐘中心就吸附
	if hand.position.distance_to(clock_center) < SNAP_DISTANCE:
		hand.position = clock_center
		
		if hand == hour_hand:
			hour_snapped = true
		else:
			minute_snapped = true
			
		dragging = null
		
		# 兩根都歸位了
		if hour_snapped and minute_snapped:
			snap_sound.play()
			set_process_input(false)
			# 等一點時間在切過去，讓玩家看清楚發生了什麼
			await get_tree().create_timer(1.2).timeout
			hide()
			minigame_completed.emit()
		
		
func _on_hint_button_pressed() -> void:
	print('hintButton test')
	snap_hint.show()
	hint_button.disabled = true # 只能看到一次
