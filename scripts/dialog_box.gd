extends CanvasLayer

signal dialogue_finished

@onready var label: Label = $Control/Panel/Label
@onready var panel: Panel = $Control/Panel

var lines: Array = []
var current_line: int = 0

func show_dialogue(dialogue: Array):
	lines = dialogue
	current_line = 0
	panel.visible = true
	label.text = lines[current_line]
	
func next_line():
	current_line += 1
	if current_line >= lines.size():
		hide_dialogue()
	else:
		label.text = lines[current_line]
		
func hide_dialogue():
	panel.visible = false
	dialogue_finished.emit()

func dialogue_is_visible() -> bool:
	return panel.visible
