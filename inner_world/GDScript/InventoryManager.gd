extends Node

# 定义一个信号，当物品栏数据变化时，通知所有监听者（比如 UI）
signal inventory_updated

# 10个槽位，-1 代表空
var slots = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
var back_pack = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]

var no_scale = [2]

# 物品图鉴：ID -> 图片路径
const ITEM_DATA = {
	0: {"name": "Player", "path": "res://player/player.png"},
	1: {"name": "apple", "path": "res://source/items/apple.png" },
	2: {"name": "sword", "path": "res://source/items/sword.png" },
	3: {"name": "key", "path": "res://source/items/key.png" },
	4: {"name": "粗糙的地球仪", "path": "res://source/furniture/globe.png"},
	5: {"name": "笔记本", "path": "res://source/items/grandbook.png", 
	"more":"一本羊皮笔记本，名字写着 Maris Corwen 。整本有七成页数被撕掉，断口不齐，像是有人匆忙撕的，又像被什么人一页页扯下来烧掉了。里面貌似夹着什么东西...",
	"view":"grandpa's book"},
	6: {"name": "mirror", "path": "res://source/furniture/mirror.png"},
	7: {"name": "Map", "path": "res://source/items/Map.png"},
	8: {"name": "五年高考三年模拟", "path": "res://53en.png", "more": "一本来自神秘の某东方大国的\n教辅书\n中国学生提高一分，干掉千人\n能量巨大"},
	9: {"name": "赢在微点", "path": "res://yzwd.jpg", "more": "UP学校正在使用的一轮复习书..."},
	10:{"name": "户籍册", "path":"res://source/items/id_book.png", "more":"一本深色硬皮小册，封面压印着金色国徽","view":"id_book"},
	11:{"name": "死亡登记回执", "path":"res://source/items/paper.png", "more":"一张厚纸，边缘有红蜡封痕，已被拆开。纸面有些发皱，像是被攥过。","view":"died_paper"},
	12:{"name": "铁盒", "path":"res://source/furniture/iron_bucket.png"},
	13:{"name": "一叠旧纸", "path":"res://source/items/old_paper.png", "more":"一叠没有装订的纸片，大小不一，边角卷起。有些是杂货铺的账单，有些是教堂的蜡烛钱记录。字迹是同一个人的，很轻，像是写的时候不敢用力。","view":"old_paper"},
	14:{"name": "日记本", "path":"res://source/items/book.png", "more":"一本日记本，但是基本上全都被撕掉了，只剩下一页","view":"diary_book"},
	
}
# 添加物品（自动放入第一个空位）
func add_item(item_id: int) -> bool:
	for i in range(slots.size()):
		if slots[i] == -1:
			slots[i] = item_id
			inventory_updated.emit()  # 发出信号，通知 UI 刷新
			return true
	for i in range(back_pack.size()):
		if back_pack[i] == -1:
			back_pack[i] = item_id
			inventory_updated.emit()  # 发出信号，通知 UI 刷新
			return true
	return false

# 移除物品
func remove_item(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slots.size():
		return -1
	var item_id = slots[slot_index]
	slots[slot_index] = -1
	inventory_updated.emit()
	return item_id

# 获取物品图标路径（供 UI 显示用）
func get_item_texture(item_id: int) -> String:
	var dict = ITEM_DATA.get(item_id, {})
	return dict.get("path", "")
