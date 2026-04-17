extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var illustration_rect: TextureRect = $Illustration
@onready var dialog_box = $DialogBox
@onready var vfx_overlay: ColorRect = $VFXOverlay

var BEATS: Array = []
var _current_beat: int = 0
var _ending: bool = false
var _active_tween: Tween

func _ready() -> void:
	background.color = Color.BLACK
	illustration_rect.modulate.a = 0
	vfx_overlay.modulate.a = 0
	_load_beats_from_json()
	dialog_box.dialogue_finished.connect(_on_beat_finished)
	
	if BEATS.size() > 0:
		_show_beat(0)

func _load_beats_from_json() -> void:
	var file = FileAccess.open("res://assets/data/opening.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json_data = JSON.parse_string(content)
		if typeof(json_data) == TYPE_ARRAY:
			for item in json_data:
				if item.has("bg") and typeof(item["bg"]) == TYPE_STRING:
					item["bg"] = Color(item["bg"])
				BEATS.append(item)

func _show_beat(index: int) -> void:
	var beat = BEATS[index]
	
	# 如果有正在進行的動畫就先取消，避免衝等
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	_active_tween = create_tween().set_parallel(true)
	
	# 1. 處理閃白 (Flash)
	if beat.get("flash", false):
		vfx_overlay.modulate.a = 1.0
		_active_tween.tween_property(vfx_overlay, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# 2. 背景顏色與圖片切換
	_active_tween.tween_property(background, "color", beat.get("bg", Color.BLACK), 0.5)
	
	if beat.has("illustration") and beat["illustration"] != "":
		# 檢查是否為新圖
		var is_new_image = illustration_rect.texture == null or illustration_rect.texture.resource_path != beat["illustration"]
		
		if is_new_image:
			var tex = load(beat["illustration"])
			if tex:
				illustration_rect.texture = tex
				# 只有新圖才需要淡入
				illustration_rect.modulate.a = 0
				_active_tween.tween_property(illustration_rect, "modulate:a", 1.0, 0.8)
				
				# --- 肯·伯恩斯縮放效果 (Ken Burns) ---
				# 只有新圖才從 1.0 開始，並緩慢放大
				illustration_rect.scale = Vector2(1.0, 1.0)
				# 延遲設定 pivot，確保 size 已經正確
				illustration_rect.pivot_offset = illustration_rect.size / 2
				_active_tween.tween_property(illustration_rect, "scale", Vector2(1.05, 1.05), 10.0).set_trans(Tween.TRANS_SINE)
	else:
		_active_tween.tween_property(illustration_rect, "modulate:a", 0.0, 0.5)

	# 3. 處理震動 (Shake)
	if beat.get("shake", false):
		_trigger_shake()

	# 4. 啟動對話 (傳入 speed 參數)
	var speed = beat.get("speed", 1.0)
	dialog_box.show_dialogue([beat], speed)

func _trigger_shake():
	var original_pos = illustration_rect.position
	var shake_tween = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		shake_tween.tween_property(illustration_rect, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(illustration_rect, "position", original_pos, 0.05)

func _on_beat_finished() -> void:
	_current_beat += 1
	if _current_beat >= BEATS.size():
		_end_cutscene()
	else:
		_show_beat(_current_beat)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_end_cutscene()
		return
	if not (event is InputEventKey and event.pressed) and \
	   not (event is InputEventMouseButton and event.pressed):
		return
	dialog_box.next_line()

func _end_cutscene() -> void:
	if _ending: return
	_ending = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(illustration_rect, "modulate:a", 0.0, 1.5)
	tween.tween_property(background, "color", Color.BLACK, 1.5)
	tween.tween_property(dialog_box.panel, "modulate:a", 0.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")
