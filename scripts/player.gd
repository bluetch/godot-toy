extends CharacterBody2D

const SPEED = 300.0
var near_object = null

@onready var dialogue_box = $'../DialogBox'
@onready var repair_minigame = $'../RepairMinigame'


enum State { IDLE, TALKING_BEFORE, REPAIRING, TALKING_AFTER }
var state: State = State.IDLE

func _ready():
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	repair_minigame.minigame_completed.connect(_on_repair_completed)

func _on_dialogue_finished():
	if state == State.TALKING_BEFORE and near_object:
		state = State.REPAIRING
		repair_minigame.start()
	else:
		state = State.IDLE
		
func _on_repair_completed():
	near_object.repair()
	near_object.animated_sprite_2d.play("idle")
	state = State.TALKING_AFTER
	dialogue_box.show_dialogue(near_object.dialogue_after)

func _physics_process(delta: float) -> void:
	if state == State.REPAIRING:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	velocity = direction.normalized() * SPEED
	move_and_slide()
	
	if near_object and not near_object.repaired and Input.is_action_just_pressed("interact"):
		if dialogue_box.dialogue_is_visible():
			dialogue_box.next_line()
		elif state == State.IDLE:
			state = State.TALKING_BEFORE
			dialogue_box.show_dialogue(near_object.dialogue_before)
	elif near_object and near_object.repaired and state == State.TALKING_AFTER:
		if Input.is_action_just_pressed("interact"):
			dialogue_box.next_line()
