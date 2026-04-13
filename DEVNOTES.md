# DEVNOTES — 玩具工廠 開發手冊

這份文件是給**未來的自己**看的內部筆記。
記錄架構決策、踩坑紀錄、各腳本責任邊界，以及開發待辦。

---

## 目前里程碑進度

### ✅ Milestone 1（2026-05-02，超前 23 天完成）
- [x] 開場過場場景
- [x] 玩家移動與互動系統
- [x] 時鐘人可被找到、互動
- [x] 打字機式對話框（修復前後各一段）
- [x] 指針拖曳修復小遊戲
- [x] 修復後玩具走向角落播日記動畫
- [x] 一天結束黑屏過場

### 🔄 Milestone 2（2026-07-02）
- [ ] Start screen（練習場景切換）
- [ ] 探索感場景（箱子、背景層次）
- [ ] 第 2 個玩具（四驅車，不同修復方式）
- [ ] 第 3 個玩具（魔術方塊或 LEGO，視時程）
- [ ] 對話內容深化
- [ ] 角色自繪圖替換 AI 圖
- [ ] 找人試玩，根據回饋調整

---

## 架構設計

### 核心原則：主場景協調模式

```
Player  →（signal: interact_requested）→  Game
                                           ↓
                                      DialogBox
                                      RepairMinigame
                                      DayTransition
```

**為什麼這樣設計：**  
早期版本讓 `Player` 直接用相對路徑抓 UI 節點（`$"../DialogBox"`）。  
這樣做很脆弱——只要節點樹改一次，所有路徑都要跟著修。  
現在 `Player` 只負責「移動」和「發出互動請求」，  
`Game` 接手後續所有流程，比較穩定，擴充新玩具也更容易。

### 流程狀態機（game.gd）

```gdscript
enum FlowState { IDLE, TALKING_BEFORE, REPAIRING, TALKING_AFTER }
```

狀態轉換：
```
IDLE → (玩家按 E) → TALKING_BEFORE
TALKING_BEFORE → (對話結束) → REPAIRING
REPAIRING → (小遊戲完成) → TALKING_AFTER
TALKING_AFTER → (對話結束) → IDLE + 觸發 DayTransition
```

`interaction_locked` 在進入非 IDLE 狀態時設為 `true`，
讓玩家無法移動或再次觸發互動，最後回到 IDLE 時解除。

---

## 各腳本責任邊界

### `game.gd` — 流程協調者
- 持有所有子系統的 reference（@onready）
- 監聽 Player、DialogBox、RepairMinigame 的 signal
- 根據 FlowState 決定下一步叫誰做什麼
- **不負責**：移動、UI 本身的顯示細節、修復判定邏輯

### `player.gd` — 移動 + 請求互動
- 處理 WASD 移動（physics_process）
- 偵測靠近的物件（`near_object`，由 `toy.gd` 的 Area2D 設定）
- 按 E 時 emit `interact_requested(target)`
- `interaction_locked = true` 時靜止不動
- **不負責**：對話流程、顯示任何 UI

### `toy.gd` — 玩具個體（extends Area2D）
- 存放對話資料（`dialogue_before`, `dialogue_after`）
- `repair()` 函式：設定 `repaired = true`，播動畫，改顏色
- `_process` 裡處理修復後走向目標位置的移動邏輯
- Area2D signal 管理 `near_object` 和互動提示 label 顯示
- **不負責**：誰來呼叫 repair、對話框怎麼顯示

### `dialog_box.gd` — 打字機對話框（extends CanvasLayer）
- `show_dialogue(Array)` 啟動一段對話
- 打字機效果用遞迴 Timer 實作（`_type_next_char`）
- 按 E 時：打字中 → 快進；打完 → 下一句；沒有下一句 → emit `dialogue_finished`
- **不負責**：決定什麼時候顯示什麼對話

### `repair_minigame.gd` — 指針修復小遊戲
- `start()` 啟動小遊戲
- 玩家用滑鼠拖曳指針到正確角度
- 完成後 emit `minigame_completed`
- **不負責**：之後的對話或過場

### `opening_cutscene.gd` — 開場過場
- 播放完畢後切換到主場景
- `Esc` 可跳過

### `day_transition.gd` — 一天結束過場
- 黑屏淡入/淡出動畫
- `start()` 由 `game.gd` 呼叫

---

## 踩坑紀錄

### 打字機遞迴 Timer 殘留問題
**症狀：** 快速跳過對話時，舊的 timer 還在背景跑，導致文字繼續一個字一個字出現。  
**根因：** `create_timer` 建立的 timer 如果沒有用 `CONNECT_ONE_SHOT` 會持續觸發。  
**解法：** 用 `CONNECT_ONE_SHOT` + 在 `_finish_typing` 裡把 `_is_typing = false`，讓下次 `_type_next_char` 一開始就 return。

```gdscript
# 正確寫法
get_tree().create_timer(CHAR_DELAY).timeout.connect(_type_next_char, CONNECT_ONE_SHOT)
```

### `near_object` 競態問題
**症狀：** 玩家站在玩具邊界邊緣時，`body_exited` 比 `interact_requested` 先觸發，`near_object` 變成 null。  
**現狀：** 目前 `game.gd` 的 `_on_player_interact_requested` 有 `if target == null` 防護，暫時夠用。  
**未來：** 如果玩具數量增加，要考慮改成更可靠的 overlap 偵測方式。

### 玩具對話資料硬寫在 toy.gd
**現狀：** 時鐘人的台詞直接寫在 `toy.gd` 的 var 裡。  
**問題：** 加更多玩具後，每個玩具都要修改 `toy.gd` 或繼承，不好維護。  
**計劃：** 里程碑 2 考慮改成 `@export var dialogue_before: Array`（在 Inspector 設定），或改用獨立的 JSON/Resource 資料檔。

### 動畫名稱有 typo
`toy.gd` 第 48 行：`animated_sprite_2d.play("dialy")` — 應該是 `"diary"`。  
目前可以跑是因為 Godot 找不到動畫時靜默失敗，不是真的 OK。待修。

---

## 場景結構

```
game.tscn
├── Player (CharacterBody2D)
├── ClockMan / Toy (Area2D)
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D
│   └── Label  ← 互動提示「按 E」
├── DialogBox (CanvasLayer)
│   └── Control/Panel/Label
├── RepairMinigame (CanvasLayer or Node)
├── DayTransition (CanvasLayer)
└── Background / TileMap（進行中）
```

---

## 資產目錄

```
assets/
├── backgrounds/    場景背景圖
├── sprites/        玩家、玩具、tile 測試素材
├── images/         修復小遊戲 UI 圖
├── audio/          音效
└── fonts/          字體
```

---

## 近期技術待辦

- [ ] 修正 `animated_sprite_2d.play("dialy")` typo → `"diary"`
- [ ] 對話資料改為 `@export`（方便 Inspector 設定，不用改程式）
- [ ] Start screen 場景 + 場景切換系統
- [ ] 追加第 2 個玩具（不同修復小遊戲方式）
- [ ] Tile-based 地板: 確立 tileset 規格與比例
- [ ] 角色 sprite sheet 換成自繪版本
- [ ] 加入音效觸發點（修復完成、對話開始、一天結束）

---

## Godot 概念快查

### UI vs 世界座標
| 類型 | 節點 | 定位方式 |
|------|------|----------|
| 遊戲世界（角色、玩具）| Node2D | `position` 座標 |
| UI（對話框、血條）| Control + CanvasLayer | Anchor + Offset |

### Anchor 常用預設
```gdscript
set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # 撐滿父節點
```

### Timer（一次性）
```gdscript
get_tree().create_timer(0.04).timeout.connect(func_name, CONNECT_ONE_SHOT)
```

### Signal 連接
```gdscript
# game.gd 的典型用法
player.interact_requested.connect(_on_player_interact_requested)
dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
```

---

## 故事核心備忘（開發參考）

- 時鐘人台詞裡的「文文」= 結依小時候的暱稱，是重大伏筆。第一次出現時玩家不會發現是主角。
- 結依目前名字是改過的（算命），改名前的舊名字是謎題核心，尚未定案。
- 工廠是陷阱，不是救援機構——這個資訊不能太早揭露。

---

*文件隨開發同步更新。*
