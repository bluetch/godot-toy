extends Control

@onready var menu_container: VBoxContainer = $MenuContainer
@onready var continue_button: Button = $MenuContainer/ContinueButton
@onready var new_game_button: Button = $MenuContainer/NewGameButton
@onready var load_game_button: Button = $MenuContainer/LoadGameButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var quit_button: Button = $MenuContainer/QuitButton

const COLOR_NORMAL = Color(0.91, 0.835, 0.69) # E8D5B0 米白
const COLOR_HOVER = Color(1.0, 0.95, 0.75) # 更亮的暖黃

func _ready() -> void:
	# 先把所有按鈕放進「虛擬包裝盒」，讓它們真正抽離排版系統
	_wrap_buttons_for_scale()
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 幫每個可點選的按鈕加上 hover 效果
	_setup_hover(new_game_button)
	_setup_hover(quit_button)

# 模擬 CSS `position: absolute` 的神級寫法：
# 在遊戲執行瞬間，動態幫每個按鈕套上一個 Control 包裝盒。
# 這樣你在編輯器裡依然可以直接排版按鈕，但在遊戲裡它們的縮放會完全獨立！
func _wrap_buttons_for_scale() -> void:
	var buttons = [continue_button, new_game_button, load_game_button, settings_button, quit_button]
	
	for btn in buttons:
		var wrapper = Control.new()
		# 抓出按鈕原本正確的長寬，教給包裝盒去佔位
		wrapper.custom_minimum_size = btn.get_combined_minimum_size()
		
		# 記錄原本的順序，替換進去
		var idx = btn.get_index()
		menu_container.add_child(wrapper)
		menu_container.move_child(wrapper, idx)
		
		# 把按鈕丟進包裝盒，並設定撐滿
		btn.reparent(wrapper)
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _setup_hover(button: Button) -> void:
	button.mouse_entered.connect(_on_hover_in.bind(button))
	button.mouse_exited.connect(_on_hover_out.bind(button))
	
func _on_hover_in(button: Button) -> void:
	if button.has_meta("hover_tween"):
		var old_tween = button.get_meta("hover_tween")
		if is_instance_valid(old_tween):
			old_tween.kill()

	button.z_index = 10
	var tween = create_tween()
	button.set_meta("hover_tween", tween)
	
	# 往左邊平移 12 pixel
	tween.tween_property(button, "position:x", -12.0, 0.1)
	button.add_theme_color_override("font_color", COLOR_HOVER)

func _on_hover_out(button: Button) -> void:
	if button.has_meta("hover_tween"):
		var old_tween = button.get_meta("hover_tween")
		if is_instance_valid(old_tween):
			old_tween.kill()

	button.z_index = 0
	var tween = create_tween()
	button.set_meta("hover_tween", tween)
	
	# 恢復原位
	tween.tween_property(button, "position:x", 0.0, 0.1)
	button.add_theme_color_override("font_color", COLOR_NORMAL)
	
func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/opening_cutscene.tscn")
	
func _on_quit_pressed() -> void:
	get_tree().quit()
