extends CharacterBody2D

const SPEED = 300.0

signal interact_requested(target)

# 目前站在玩家旁邊的互動物件（玩具、箱子、角落等），離開範圍時會變成 null
var near_object = null
var interaction_locked := false
# 對話剛結束時暫時擋住互動，避免同一次按 E 又立刻把對話打開。
var _block_interact_until_release := false

func _ready():
	pass

func consume_interact_until_release() -> void:
	_block_interact_until_release = true

# _physics_process 每個物理幀執行一次（預設 60fps）
# 適合處理移動、碰撞等需要穩定頻率的邏輯
func _physics_process(_delta: float) -> void:
	# 等玩家真的放開互動鍵，才解除這次的輸入鎖。
	if _block_interact_until_release and not Input.is_action_pressed("interact"):
		_block_interact_until_release = false

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

	# 站在可互動物件旁邊按 E，交給 Game 決定後續流程
	if not interaction_locked and not _block_interact_until_release and near_object and Input.is_action_just_pressed("interact"):
		interact_requested.emit(near_object)
