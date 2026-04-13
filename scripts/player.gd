extends CharacterBody2D

const SPEED = 300.0

signal interact_requested(target)

# 目前站在玩家旁邊的互動物件（玩具），離開範圍時會變成 null
var near_object = null
var interaction_locked := false

func _ready():
	pass

# _physics_process 每個物理幀執行一次（預設 60fps）
# 適合處理移動、碰撞等需要穩定頻率的邏輯
func _physics_process(delta: float) -> void:
	# 對話、修復、過場期間由 Game 控制鎖住玩家
	if interaction_locked:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		# 讀取方向鍵輸入，計算移動速度
		var direction = Vector2.ZERO
		direction.x = Input.get_axis("move_left", "move_right")
		direction.y = Input.get_axis("move_up", "move_down")
		velocity = direction.normalized() * SPEED
		move_and_slide()

	# 站在未修復的玩具旁邊按 E，交給 Game 決定後續流程
	if not interaction_locked and near_object and not near_object.repaired and Input.is_action_just_pressed("interact"):
		interact_requested.emit(near_object)
