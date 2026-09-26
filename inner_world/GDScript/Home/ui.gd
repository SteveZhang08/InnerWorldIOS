extends CanvasLayer

@onready var item_slots = [
	$InventoryBar/Item_0,
	$InventoryBar/Item_1,
	$InventoryBar/Item_2,
	$InventoryBar/Item_3,
	$InventoryBar/Item_4,
	$InventoryBar/Item_5,
	$InventoryBar/Item_6,
	$InventoryBar/Item_7,
	$InventoryBar/Item_8,
	$InventoryBar/Item_9,
]

func _ready():
	# 连接全局信号，每当物品变化时刷新界面
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	# 初始化显示
	_on_inventory_updated()

func _on_inventory_updated():
	# 遍历所有槽位，从全局数据中读取并显示
	for i in range(item_slots.size()):
		var slot = item_slots[i]
		var item_id = InventoryManager.slots[i]
		if item_id == -1:
			slot.texture = null
		else:
			var path = InventoryManager.get_item_texture(item_id)
			if path != "":
				slot.texture = load(path)
			else:
				slot.texture = null
