extends Node

# player_state.gd (Global Singleton)
# ---------------------------------------------------------
# 此檔案為遊戲的核心狀態管理器（Autoload）。
# 負責處理：
# 1. 背包系統與道具資料庫 (ITEM_DB)
# 2. 遊戲進程與教學狀態 (TutorialState)
# 3. 從 JSON 載入文字資料（場景物件描述、系統提示）
# 4. NPC 名稱映射系统（??? -> 真名）
# ---------------------------------------------------------

# 當原本沒名字的 NPC 告訴我們名字後，發出這個訊號讓 UI 同步
signal name_learned(original_name, new_name)
signal inventory_changed

# 存放從 JSON 載入的場景物件描述
var _inspectables_data: Dictionary = {}
var _items_data: Dictionary = {}

func _ready() -> void:
	_load_inspectables_data()
	_load_items_data()

func _load_inspectables_data() -> void:
	var path = "res://assets/data/inspectables.json"
	
	if not FileAccess.file_exists(path):
		printerr("[Error] 找不到 JSON 檔案：", path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("[Error] 無法讀取 JSON 檔案內容：", path)
		return
		
	var json_text = file.get_as_text()
	var content = JSON.parse_string(json_text)
	
	if content == null:
		printerr("[Error] JSON 解析失敗！請檢查 ", path, " 的格式是否正確。")
		_inspectables_data = {}
		return
		
	if typeof(content) == TYPE_DICTIONARY:
		_inspectables_data = content
	else:
		printerr("[Error] JSON 格式錯誤：應為 Dictionary 格式 (", path, ")")

func _load_items_data() -> void:
	var path = "res://assets/data/items.json"
	if not FileAccess.file_exists(path):
		printerr("[Error] 找不到物品資料庫：", path)
		return
		
	var json_text = FileAccess.get_file_as_string(path)
	var content = JSON.parse_string(json_text)
	
	if content == null:
		printerr("[Error] items.json 解析失敗！請檢查格式。")
		_items_data = {}
		return
		
	if typeof(content) == TYPE_DICTIONARY:
		_items_data = content
	else:
		printerr("[Error] items.json 格式錯誤：應為 Dictionary")

# 供外部獲取 JSON 裡的文字陣列
func get_inspectable_lines(id: String, type: String = "desc") -> Array:
	if _inspectables_data.has(id):
		var entry = _inspectables_data[id]
		if entry.has(type):
			# 需要轉成 Array[String]
			var result: Array[String] = []
			for line in entry[type]:
				result.append(str(line))
			return result
	return []

# 供外部獲取 JSON 裡的單行文字 (例如: obtained)
func get_inspectable_text(id: String, type: String = "obtained") -> String:
	if _inspectables_data.has(id):
		var entry = _inspectables_data[id]
		if entry.has(type):
			return str(entry[type])
	return ""

# 獲取系統預設台詞
func get_system_lines(key: String) -> Array[String]:
	if _inspectables_data.has("system_defaults"):
		var defaults = _inspectables_data["system_defaults"]
		if defaults.has(key):
			if typeof(defaults[key]) == TYPE_ARRAY:
				var result: Array[String] = []
				for line in defaults[key]:
					result.append(str(line))
				return result
			else:
				return [str(defaults[key])]
	return []

func get_system_text(key: String) -> String:
	if _inspectables_data.has("system_defaults"):
		var defaults = _inspectables_data["system_defaults"]
		if defaults.has(key):
			return str(defaults[key])
	return ""

# --- 物品資料存取 ---

func get_item_name(item_id: String) -> String:
	if _items_data.has(item_id):
		return _items_data[item_id].get("name", "未命名物品")
	return ""

func get_item_desc(item_id: String) -> String:
	if _items_data.has(item_id):
		return _items_data[item_id].get("desc", "沒有描述。")
	return ""

func has_item_data(item_id: String) -> bool:
	return _items_data.has(item_id)

# --- 遊戲進度追蹤 ---
enum TutorialState {
	START = 0,
	TOLD_TO_FIND_MOUTH = 1,
	HAS_MOUTH = 2,
	SAW_FROZEN = 3,
	HAS_SPRING = 4
}

var state: TutorialState = TutorialState.START

# --- 背包與道具資料 ---
var inventory: Array[String] = []

# 動態名稱系統：key 為 JSON 中的 speaker 原名，value 為顯示名稱
var known_names = {
	"時鐘人": "???"
}

# (ITEM_DB 已遷移至 items.json)

func add_item(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)
		inventory_changed.emit()

# 讓主角認識某人的真名
func learn_name(original_name: String, new_name: String) -> void:
	known_names[original_name] = new_name
	name_learned.emit(original_name, new_name)
	print("結依認識了：", new_name)
