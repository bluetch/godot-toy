extends Node2D

@onready var icon: Sprite2D = $Sprite2D
var player: CharacterBody2D

var _target_visible: bool = false
var _current_tween: Tween

func _ready():
	# 初始隱藏，並縮小
	modulate.a = 0
	scale = Vector2.ZERO
	visible = false

func _process(_delta):
	if player == null:
		return
	
	# 檢查玩家是否靠近物件
	var is_near = player.near_object != null
	
	# 狀態切換：只有在狀態改變時才觸發動畫 (避免重複觸發)
	if is_near != _target_visible:
		_target_visible = is_near
		_animate_visibility(_target_visible)
	
	if visible and player.near_object != null:
		# 1. 位置更新：跟隨物件
		global_position = player.near_object.global_position + Vector2(0, -65)

# 處理「出現在場景中」的動畫
func _animate_visibility(should_show: bool):
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	_current_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if should_show:
		visible = true
		_current_tween.tween_property(self, "scale", Vector2(1, 1), 0.2)
		_current_tween.tween_property(self, "modulate:a", 0.8, 0.2) # 稍微帶一點透明感，更融入背景
	else:
		# 縮小並淡出
		var fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.15)
		fade_tween.chain().step_finished.connect(func(): visible = false)
