extends CanvasLayer

@onready var bar: ProgressBar = $CenterContainer/VBoxContainer/Bar
@onready var hint_label: Label = $CenterContainer/VBoxContainer/HintLabel

# when fixed send the signal to let player.gd know can trigger
signal repair_completed

const REPAIR_TIME = 2.0
var is_repairing: bool = false
var progress: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# hide at the beginining
	hide_ui()

func start():
	# call from outside (e.g. player.gd)
	progress = 0.0
	bar.value = 0
	visible = true
	is_repairing = false
	
func hide_ui():
	visible = false
	progress = 0.0
	bar.value = 0
	
func _process(delta: float) -> void:
	# UI 隱藏時不需要處理任何邏輯
	if not visible:
		return
	if Input.is_action_pressed("interact"):
		is_repairing = true
		# delta 是每楨經過的秒數
		# 除以 REPAIR_TIME再乘 100，讓進度再REPAIR_TIME 秒後剛好到100
		progress += delta / REPAIR_TIME * 100
		progress = min(progress, 100) # 不超過100
		bar.value = progress
		hint_label.text = "按住E修復..."
		
		if progress >= 100:
			hide_ui()
			repair_completed.emit() # 通知player.gd
			
	else:
		if is_repairing:
			progress = 0.0
			bar.value = 0
			is_repairing = false
			hint_label.text = "按住 E 修復 ..."
			
