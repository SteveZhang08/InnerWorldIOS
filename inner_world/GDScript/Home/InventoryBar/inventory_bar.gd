extends Panel

@onready var item_slots = [
	$Item_0,
	$Item_1,
	$Item_2,
	$Item_3,
	$Item_4,
	$Item_5,
	$Item_6,
	$Item_7,
	$Item_8,
	$Item_9
]

@onready var item_zone = $Item_Zone
var item_zone_id = 0
var action = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for slot in item_slots:
		slot.clicked.connect(_on_slot_clicked)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if item_zone_id > 0:
						item_zone_id -= 1
					else:
						item_zone_id = 9
				MOUSE_BUTTON_WHEEL_DOWN:
					if item_zone_id < 9:
						item_zone_id += 1
					else:
						item_zone_id = 0
			item_zone_show(item_zone_id)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			item_zone_id = event.keycode - KEY_1
		elif event.keycode == KEY_0:
			item_zone_id = 9
		item_zone_show(item_zone_id)

func item_zone_show(id):
	item_zone.position = Vector2(item_slots[id].position.x-5, item_slots[id].position.y-3)

func _on_slot_clicked(slot_index: int):
	item_zone_id = slot_index
	item_zone_show(slot_index)

func _get_item_id():
	return InventoryManager.slots[item_zone_id]

func _get_item_texture():
	var item_id = InventoryManager.get_item_texture(_get_item_id())
	if item_id:
		return InventoryManager.get_item_texture(_get_item_id())
	else:
		return
