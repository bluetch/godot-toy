extends Node2D

# --- 狀態機 (State Machine) ---
# 類比 React 裡的狀態管理。我們定義多個模式，確保玩家不會在說話時還能走路。
# IDLE: 自由移動
# TALKING_BEFORE: 修復前對話
# REPAIRING: 修復遊戲進行中
# TALKING_AFTER: 修復後對話
# INSPECTING: 一般調查（如看書櫃、箱子）
enum FlowState { IDLE, TALKING_BEFORE, REPAIRING, TALKING_AFTER, INSPECTING }

# --- 節點參考 (@onready) ---
@onready var player: CharacterBody2D = $Player
@onready var dialogue_box = $DialogBox
@onready var repair_minigame = $RepairMinigame
@onready var day_transition: CanvasLayer = $DayTransition

var state: FlowState = FlowState.IDLE
var current_target = null  # 記錄目前正在跟哪一個物件互動

func _ready() -> void:
	# 基礎節點檢查，確保場景掛載正確
	if player == null:
		push_error("Game 找不到 Player 節點。")
		return

	# 動態注入 (Dynamic Injection)
	# 把常用的 UI (背包、互動提示) 預載進來並掛載到場景中
	# 類比網頁裡的 appendChild(element)
	var inv_hud = preload("res://scenes/inventory_hud.tscn").instantiate()
	add_child(inv_hud)

	var prompt = preload("res://scenes/interact_prompt.tscn").instantiate()
	prompt.player = player
	add_child(prompt)

	# --- 事件監聽 (Signals Connection) ---
	# 類比 JS 的 element.addEventListener('event', callback)
	player.interact_requested.connect(_on_player_interact_requested)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	repair_minigame.minigame_completed.connect(_on_repair_completed)

# 當玩家靠近物件並按鍵時觸發
func _on_player_interact_requested(target) -> void:
	if state != FlowState.IDLE: return  # 如果已經在說話，就忽略新的互動
	if target == null: return

	# 分流處理：根據節點所屬的群組 (Groups) 決定行為
	# Group 類比 CSS 的 Class 名稱，例如這是一個 .toy 還是 .inspectable
	if target.is_in_group("toy"):
		_handle_toy_interaction(target)
	elif target.is_in_group("inspectable"):
		_handle_inspectable_interaction(target)

# 處理玩具邏輯：觸發完整的修復任務流
func _handle_toy_interaction(target) -> void:
	if target.repaired: return

	current_target = target
	state = FlowState.TALKING_BEFORE
	player.interaction_locked = true  # 鎖住角色移動
	
	# 優先尋找物件自定義的 interact() 邏輯，若沒寫則使用預設屬性
	if target.has_method("interact"):
		dialogue_box.show_dialogue(target.interact())
	else:
		dialogue_box.show_dialogue(target.dialogue_before)

# 處理調查邏輯：單純顯示文字
func _handle_inspectable_interaction(target) -> void:
	var lines = target.interact()
	current_target = target
	state = FlowState.INSPECTING
	player.interaction_locked = true
	dialogue_box.show_dialogue(lines)

# 當對話框發出結束信號 (dialogue_finished) 時的回調
func _on_dialogue_finished() -> void:
	match state:
		FlowState.TALKING_BEFORE:
			# 修復前對話結束 -> 檢查是否具備修復條件
			if current_target.has_method("is_ready_for_repair") and not current_target.is_ready_for_repair():
				# 條件未滿足，回到 IDLE 狀態，解開移動鎖
				_reset_to_idle()
			else:
				# 進入修復遊戲
				state = FlowState.REPAIRING
				repair_minigame.start()
				
		FlowState.TALKING_AFTER:
			# 修復後對話結束 -> 執行過場並切換到下一天
			day_transition.start()
			_reset_to_idle()
			
		FlowState.INSPECTING:
			# 調查讀完，直接解鎖
			_reset_to_idle()

# 重置狀態與玩家鎖定
func _reset_to_idle() -> void:
	# consume_interact_until_release() 是為了解決按一次鍵會觸發兩次對話的「黏滯感」
	player.interaction_locked = false
	player.consume_interact_until_release()
	current_target = null
	state = FlowState.IDLE

# 當小遊戲過關時的回調
func _on_repair_completed() -> void:
	if current_target == null: return

	current_target.repair() # 執行玩具內部的修復函式
	current_target.animated_sprite_2d.play("idle")
	
	# 切換狀態並啟動修復後的對話
	state = FlowState.TALKING_AFTER
	dialogue_box.show_dialogue(current_target.dialogue_after)

# 全域輸入處理：按鍵推進對話
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"): return
	
	# 如果正在說話中，按鍵會觸發下一行文字
	if state in [FlowState.TALKING_BEFORE, FlowState.TALKING_AFTER, FlowState.INSPECTING]:
		if dialogue_box.dialogue_is_visible():
			dialogue_box.next_line()
