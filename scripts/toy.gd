extends Area2D

@onready var label: Label = $Label
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 修復後玩具要走去的目標位置（在 Inspector 設定）
@export var factory_position: Vector2 = Vector2(100, 100)

var repaired: bool = false
var WALK_SPEED = 150

# 是否已到達目標位置，用來確保動畫切換只執行一次
var _arrived: bool = false

# 修復前對話內容
var dialogue_before: Array = [
	"你知道現在幾點嗎？我已經不知道了。",
	"我以前是教具。每天早上文文都會來轉動我的指針，一邊說『媽媽，現在是八點！』⋯⋯那是我最喜歡的時刻。",
	"後來有了手錶，就沒人需要我了。再後來，家裡的狗咬壞了我的指針。我以為我就這樣結束了⋯⋯但我醒來，卻在這裡。為什麼？"
]

# 修復後對話內容
var dialogue_after: Array = [
	"⋯⋯長針指著十二，短針指著三。下午三點。",
	"我記住了。也許我還沒結束。謝謝你。"
]

func _ready():
	# 互動提示預設隱藏，靠近時才顯示
	label.visible = false

# _process 每幀執行，處理修復後的移動邏輯
func _process(delta):
	# 還沒修復就不需要移動
	if not repaired:
		return

	if global_position.distance_to(factory_position) > 5:
		# 還沒到目標：播走路動畫，往目標移動
		# move_toward 每幀移動固定距離，delta 確保速度與幀率無關
		animated_sprite_2d.flip_h = factory_position.x < global_position.x
		animated_sprite_2d.play("idle")
		global_position = global_position.move_toward(factory_position, WALK_SPEED * delta)
	else:
		# 到達目標：切換到日記動畫，只執行一次
		if not _arrived:
			_arrived = true
			animated_sprite_2d.play("dialy")

# 由 player.gd 呼叫，執行修復邏輯
func repair():
	repaired = true
	# 變色表示已修復（暫時效果，之後換成正式動畫）
	animated_sprite_2d.modulate = Color(1.2, 1.0, 0.6)
	animated_sprite_2d.play("idle")

# Area2D 內建 signal：有物體進入碰撞範圍時觸發
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not repaired:
			label.visible = true
		# 讓玩家知道自己站在這個物件旁邊
		body.near_object = self

# Area2D 內建 signal：物體離開碰撞範圍時觸發
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = false
		body.near_object = null
