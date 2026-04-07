extends Area2D

@onready var label: Label = $Label
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


var repaired: bool = false

var dialogue_before: Array = [
	"恩..我在這裡好久了",
	"我的指針壞掉了，所以被退回來了",
	"你可以幫我修好嗎？"
]

var dialogue_after: Array = [
	"謝謝你",
	"我已經很久沒有感覺到這麼溫暖了"
]

func repair():
	repaired = true
	animated_sprite_2d.modulate = Color(1.2, 1.0, 0.6)
	

func _on_body_entered(body: Node2D) -> void:
	print(body, body.is_in_group("player"))
	if body.is_in_group("player"):
		if not repaired:
			label.visible = true
		body.near_object = self


func _on_body_exited(body: Node2D) -> void:
	print("exit", body, body.is_in_group("player"))
	if body.is_in_group("player"):
		label.visible = false
		body.near_object = null
