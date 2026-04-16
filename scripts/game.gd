extends Node2D

# 目前場景只有兩種互動流程：玩具修復流程、一般調查流程。
enum FlowState { IDLE, TALKING_BEFORE, REPAIRING, TALKING_AFTER, INSPECTING }

@onready var player: CharacterBody2D = $Player
@onready var dialogue_box = $DialogBox
@onready var repair_minigame = $RepairMinigame
@onready var day_transition: CanvasLayer = $DayTransition

var state: FlowState = FlowState.IDLE
var current_target = null

func _ready() -> void:
	if player == null:
		push_error("Game 找不到 Player 節點。")
		return
	if dialogue_box == null:
		push_error("Game 找不到 DialogBox 節點。")
		return
	if repair_minigame == null:
		push_error("Game 找不到 RepairMinigame 節點。")
		return
	if day_transition == null:
		push_error("Game 找不到 DayTransition 節點。")
		return

	# 動態注入背包 UI (自動綁定 B 鍵)
	var inv_hud = preload("res://scenes/inventory_hud.tscn").instantiate()
	add_child(inv_hud)

	# 動態注入全域 Hover Prompt
	var prompt = preload("res://scenes/interact_prompt.tscn").instantiate()
	prompt.player = player
	add_child(prompt)

	player.interact_requested.connect(_on_player_interact_requested)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	repair_minigame.minigame_completed.connect(_on_repair_completed)

func _on_player_interact_requested(target) -> void:
	if state != FlowState.IDLE:
		return
	if target == null:
		return

	# 玩具會進入完整的修復流程：修復前對話 -> 修復 -> 修復後對話。
	if target.is_in_group("toy"):
		if target.repaired:
			return

		current_target = target
		state = FlowState.TALKING_BEFORE
		player.interaction_locked = true
		
		# 支援新版動態對話，若無則降級使用舊版
		if target.has_method("interact"):
			dialogue_box.show_dialogue(target.interact())
		else:
			dialogue_box.show_dialogue(target.dialogue_before)
		return

	# 一般調查物顯示描述文字，並根據是否開啟過給出不同對話
	if target.is_in_group("inspectable"):
		var lines = target.interact()
		current_target = target
		state = FlowState.INSPECTING
		player.interaction_locked = true
		dialogue_box.show_dialogue(lines)

func _on_dialogue_finished() -> void:
	if state == FlowState.TALKING_BEFORE:
		# 檢查是否符合修復條件（例如：已取得發條）
		if current_target.has_method("is_ready_for_repair") and not current_target.is_ready_for_repair():
			# 條件未滿，不進入修復，直接結束互動
			player.interaction_locked = false
			player.consume_interact_until_release()
			current_target = null
			state = FlowState.IDLE
		else:
			state = FlowState.REPAIRING
			repair_minigame.start()
	elif state == FlowState.TALKING_AFTER:
		day_transition.start()
		# 對話結束先等玩家放開 E，避免同一次輸入又重新互動。
		player.interaction_locked = false
		player.consume_interact_until_release()
		current_target = null
		state = FlowState.IDLE
	elif state == FlowState.INSPECTING:
		# 調查點讀完後直接回到可移動狀態，不觸發任何額外流程。
		player.interaction_locked = false
		player.consume_interact_until_release()
		current_target = null
		state = FlowState.IDLE

func _on_repair_completed() -> void:
	if current_target == null:
		return

	current_target.repair()
	current_target.animated_sprite_2d.play("idle")
	state = FlowState.TALKING_AFTER
	dialogue_box.show_dialogue(current_target.dialogue_after)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if state == FlowState.TALKING_BEFORE or state == FlowState.TALKING_AFTER or state == FlowState.INSPECTING:
		if dialogue_box.dialogue_is_visible():
			dialogue_box.next_line()
