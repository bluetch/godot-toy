extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 修復後玩具要走去的目標位置（在 Inspector 設定）
@export var factory_position: Vector2 = Vector2(100, 100)

var repaired: bool = false
var WALK_SPEED = 150

# 是否已到達目標位置，用來確保動畫切換只執行一次
var _arrived: bool = false

# 動態互動對話，供外部呼叫
func interact() -> Array:
	match PlayerState.state:
		PlayerState.TutorialState.START:
			PlayerState.state = PlayerState.TutorialState.TOLD_TO_FIND_MOUTH
			return _load_json_dialogue("clockman_no_mouth")
		PlayerState.TutorialState.TOLD_TO_FIND_MOUTH:
			return [{"speaker": "時鐘人", "text": "那邊有個生鏽的綠色箱子可以翻翻看，如果妳想找布料代替嘴巴的話。"}]
		PlayerState.TutorialState.HAS_MOUTH:
			PlayerState.state = PlayerState.TutorialState.SAW_FROZEN
			return _load_json_dialogue("clockman_frozen")
		PlayerState.TutorialState.SAW_FROZEN:
			return [{"speaker": "主角", "text": "（他完全不動了... 去充滿灰塵的通風口那邊，找找看有沒有發條吧。）"}]
		PlayerState.TutorialState.HAS_SPRING:
			# 此時觸發認識名字
			PlayerState.learn_name("時鐘人", "克洛斯")
			return _load_json_dialogue("clockman_ready_repair")
	return []

func is_ready_for_repair() -> bool:
	return PlayerState.state == PlayerState.TutorialState.HAS_SPRING

func _load_json_dialogue(key: String) -> Array:
	var path = "res://assets/data/tutorial.json"
	if not FileAccess.file_exists(path):
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	if typeof(content) == TYPE_DICTIONARY and content.has(key):
		return content[key]
	return []

# 修復後對話內容
var dialogue_after: Array = [
	"⋯⋯長針指著十二，短針指著三。下午三點。",
	"我記住了。也許我還沒結束。謝謝你。"
]

@export var prompt_text: String = "[ Space ] 與其互動"

func _ready():
	pass

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
		# 讓玩家知道自己站在這個物件旁邊
		body.near_object = self

# Area2D 內建 signal：物體離開碰撞範圍時觸發
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.near_object == self:
			body.near_object = null
