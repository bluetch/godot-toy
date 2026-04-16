extends Node

signal inventory_changed

enum TutorialState {
	START = 0,
	TOLD_TO_FIND_MOUTH = 1,
	HAS_MOUTH = 2,
	SAW_FROZEN = 3,
	HAS_SPRING = 4
}

var state: TutorialState = TutorialState.START

var inventory: Array[String] = []

const ITEM_DB = {
	"mouth_patch": {
		"name": "縫線布料",
		"desc": "一塊邊緣有著立體縫線的舊布料。帶有一點熟悉的溫暖，如果是給布偶的話，也許能當作嘴巴來發出聲音。"
	},
	"clock_spring": {
		"name": "生鏽的發條",
		"desc": "從通風口找到的舊發條。尺寸雖然有點大，但或許能暫時用來啟動某個停擺的發條玩具。"
	}
}

func add_item(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)
		inventory_changed.emit()
