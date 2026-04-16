extends Node2D

@onready var label: Label = $Label
var player: CharacterBody2D

func _ready():
	visible = false

func _process(_delta):
	if player == null:
		return
		
	if player.near_object != null:
		visible = true
		
		# 動態更新座標到互動物件的正上方 (加上一個垂直偏移量避免擋到物件)
		global_position = player.near_object.global_position + Vector2(0, -60)
		
		# 動態抓取提示文字
		if player.near_object.get("prompt_text") != null:
			label.text = player.near_object.prompt_text
		else:
			label.text = "[ Space ] 與其互動"
	else:
		visible = false
