extends Panel

@onready var item_slots = [
	$Item_0,
	$Item_1
]

var screen_size
var panel_width

func _ready():
	# 获取屏幕尺寸
	screen_size = get_viewport().get_visible_rect().size
	panel_width = 190.0
	# 1. 起始位置：屏幕右侧外部（x = 屏幕宽度，y 适当留空）
	global_position = Vector2(screen_size.x, 30)

func appear(target_x: float):
	visible = true
	var tween = create_tween()
	# 将 global_position.x 从当前值渐变到 target_x
	tween.tween_property(self, "global_position:x", target_x, 0.8)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

func disappear():
	var tween = create_tween()
	tween.tween_property(self, "global_position:x", screen_size.x + panel_width, 0.8)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

var item
var slots = []
var current_token = 0

func _on_bookshelf_get_item(item_idl:Array):	# 虽然一直很疑惑，但在gd中Array取代了Python的列表
	slots = []
	appear(screen_size.x - panel_width)
	var idx = 0
	for item_id in item_idl:
		slots.append(item_id)
		InventoryManager.add_item(item_id)
		idx += 1
		var add_item = InventoryManager.ITEM_DATA.get(item_id, {})
		# print("add ", add_item.get("name", "ERROR：尝试获取一个不存在或者错误的物品"))
	current_token += 1
	await  _show(item_idl, current_token)
	disappear()

func _show(item_idl:Array, my_token:int):
	var count = 0
	for slot in item_slots:
		slot.texture = null
	for i in range(item_idl.size()):
		if my_token != current_token:
			print("_show: ",my_token, "号函数被终止")
			return
		if count >= 2:
			count = 0
			if my_token != current_token:
				print("_show: ",my_token, "号函数被终止")
				return
			await get_tree().create_timer(1).timeout
			if my_token != current_token:
				print("_show: ",my_token, "号函数被终止")
				return
			for slot in item_slots:
				slot.texture = null
		var slot = item_slots[i%2]
		var item_id = slots[i]
		var path = InventoryManager.get_item_texture(item_id)
		if path != "":
			slot.texture = load(path)
		else:
			slot.texture = null
		count += 1
	await get_tree().create_timer(1.3).timeout
