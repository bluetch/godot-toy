extends CharacterBody2D

const SPEED = 300.0

# 目前站在玩家旁邊的互動物件（玩具），離開範圍時會變成 null
var near_object = null

# 取得場景中其他節點的參考（../代表往上一層再往下找）
@onready var dialogue_box = $'../DialogBox'
@onready var repair_minigame = $'../RepairMinigame'
@onready var day_transition: CanvasLayer = $"../DayTransition"

# 玩家的狀態機（同一時間只會在其中一個狀態）
# IDLE：正常移動
# TALKING_BEFORE：修復前的對話中
# REPAIRING：修復小遊戲進行中
# TALKING_AFTER：修復後的對話中
enum State { IDLE, TALKING_BEFORE, REPAIRING, TALKING_AFTER }
var state: State = State.IDLE

func _ready():
	# 用 signal 監聽對話結束和修復完成的事件
	# 類比 JavaScript 的 addEventListener
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	repair_minigame.minigame_completed.connect(_on_repair_completed)

# 對話結束時觸發
func _on_dialogue_finished():
	if state == State.TALKING_BEFORE and near_object:
		# 修復前對話結束 → 開始修復小遊戲
		state = State.REPAIRING
		repair_minigame.start()
	else:
		if state == State.TALKING_AFTER:
			# 修復後對話結束 → 觸發一天結束的過場
			day_transition.start()
			state = State.IDLE

# 修復小遊戲完成時觸發
func _on_repair_completed():
	near_object.repair()
	near_object.animated_sprite_2d.play("idle")
	state = State.TALKING_AFTER
	dialogue_box.show_dialogue(near_object.dialogue_after)

# _physics_process 每個物理幀執行一次（預設 60fps）
# 適合處理移動、碰撞等需要穩定頻率的邏輯
func _physics_process(delta: float) -> void:
	# 修復中禁止移動
	if state == State.REPAIRING:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 讀取方向鍵輸入，計算移動速度
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	velocity = direction.normalized() * SPEED
	move_and_slide()

	# 站在未修復的玩具旁邊按 E
	if near_object and not near_object.repaired and Input.is_action_just_pressed("interact"):
		if dialogue_box.dialogue_is_visible():
			# 對話中：推進到下一句
			dialogue_box.next_line()
		elif state == State.IDLE:
			# 對話未開始：開始修復前對話
			state = State.TALKING_BEFORE
			dialogue_box.show_dialogue(near_object.dialogue_before)

# _input 處理單次按鍵事件，比 _physics_process 更可靠捕捉按鍵
func _input(event: InputEvent) -> void:
	# 修復後對話中按 E 推進對話
	if state == State.TALKING_AFTER:
		if event.is_action_pressed("interact"):
			dialogue_box.next_line()
