extends Control

@onready var continue_button: Button = $MenuContainer/ContinueButton
@onready var new_game_button: Button = $MenuContainer/NewGameButton
@onready var load_game_button: Button = $MenuContainer/LoadGameButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var quit_button: Button = $MenuContainer/QuitButton

const COLOR_NORMAL = Color(0.91, 0.835, 0.69) # E8D5B0 米白
const COLOR_HOVER = Color(1.0, 0.95, 0.75) # 更亮的暖黃

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 幫每個可點選的按鈕加上 hover 效果
	_setup_hover(new_game_button)
	_setup_hover(quit_button)
	
func _setup_hover(button: Button) -> void:
	# 把縮放中心點設在「寬度的最右邊、高度的一半」，這樣就會從右側原點放大
	button.pivot_offset = Vector2(button.size.x, button.size.y / 2.0)

	button.mouse_entered.connect(_on_hover_in.bind(button))
	button.mouse_exited.connect(_on_hover_out.bind(button))
	
func _on_hover_in(button: Button) -> void:
	# 類似 CSS 的 z-index: 10
	button.z_index = 10
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.1)
	button.add_theme_color_override("font_color", COLOR_HOVER)
func _on_hover_out(button: Button) -> void:
	# 恢復原本的層級
	button.z_index = 0
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	button.add_theme_color_override("font_color", COLOR_NORMAL)
	
func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/opening_cutscene.tscn")
	
func _on_quit_pressed() -> void:
	get_tree().quit()
