extends CanvasLayer


func _ready() -> void:
	# 示範：在場景載入時讀取 JSON
	var script_data = load_json_dialogue("res://assets/data/opening.json")
	
	# 如果你有把 DialogBox 放進這個場景裡，可以這樣呼叫：
	# if has_node("DialogBox"):
	#     $DialogBox.show_dialogue(script_data)

func load_json_dialogue(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		push_error("找不到 JSON 檔案: ", file_path)
		return []
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	# 把純文字轉回 Godot 的陣列/字典
	var json_data = JSON.parse_string(content)
	
	if typeof(json_data) == TYPE_ARRAY:
		return json_data
	else:
		push_error("無法解析 JSON 或格式不是陣列")
		return []
