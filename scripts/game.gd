extends Node2D

enum FlowState { IDLE, TALKING_BEFORE, REPAIRING, TALKING_AFTER }

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

	player.interact_requested.connect(_on_player_interact_requested)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	repair_minigame.minigame_completed.connect(_on_repair_completed)

func _on_player_interact_requested(target) -> void:
	if state != FlowState.IDLE:
		return
	if target == null or target.repaired:
		return

	current_target = target
	state = FlowState.TALKING_BEFORE
	player.interaction_locked = true
	dialogue_box.show_dialogue(target.dialogue_before)

func _on_dialogue_finished() -> void:
	if state == FlowState.TALKING_BEFORE:
		state = FlowState.REPAIRING
		repair_minigame.start()
	elif state == FlowState.TALKING_AFTER:
		day_transition.start()
		player.interaction_locked = false
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
	if state == FlowState.TALKING_BEFORE or state == FlowState.TALKING_AFTER:
		if dialogue_box.dialogue_is_visible():
			dialogue_box.next_line()
