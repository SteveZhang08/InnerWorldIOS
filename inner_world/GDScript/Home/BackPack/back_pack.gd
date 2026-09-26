extends Panel

@onready var sound = $Click
@onready var item_zone = $Item_Zone
@onready var item_name_text = $Item_Name
@onready var item_details = $Item
@onready var item_details_text = $Item_Details_Text
@onready var exit_button = $EXIT
@onready var move_button = $MOVE
@onready var Item_Move = $Item_Move
@onready var view_book = $ViewBook
@onready var book_text_l = $ViewBook/Text_L
@onready var book_text_r = $ViewBook/Text_R
@onready var book_exit_button = $ViewBook/EXIT
@onready var button_pageup = $ViewBook/LEFT
@onready var button_pagedown = $ViewBook/RIGHT
@onready var view_button = $VIEW
@onready var page_flip_sound = $ViewBook/Page_Flip
@onready var image_l = $ViewBook/Image_L
@onready var image_r = $ViewBook/Image_R

var book
var item_slots = []
var slots
var back_pack
var item_zone_id = 0
@onready var player = Global_Player.player
var item_list
var item_id
var move_mob = false
var move_slot = -1
var page

signal get_item(item:int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	var target_node = get_node("/root/Main/UI/Get_Item_Info")
	get_item.connect(target_node._on_bookshelf_get_item)
	exit_button.pressed.connect(_close)
	move_button.pressed.connect(_move)
	book_exit_button.pressed.connect(_close_book_view)
	button_pagedown.pressed.connect(_page_down)
	button_pageup.pressed.connect(_page_up)
	view_button.pressed.connect(_show_page)
	var slot
	for i in range(20):
		slot = get_node("Item_"+str(i))
		item_slots.append(slot)
	for slot1 in item_slots:
		slot1.clicked.connect(_on_slot_clicked)

func _close_book_view():
	if view_book.visible:
		view_book.visible = false
		sound.play()
		_show_item()
		if book.get("page"):
			book["page"] = page

func _page_up():
	if page == 0:
		button_pageup.release_focus()
		return
	if view_book.visible:
		page -= 2
		_show_page()
		page_flip_sound.play()
		button_pageup.release_focus()
	
func _page_down():
	if page >= book.get("end",114):
		button_pagedown.release_focus()
		return
	if view_book.visible:
		page += 2
		_show_page()
		page_flip_sound.play()
		button_pagedown.release_focus()

func _show_page():
	if not view_book.visible:
		view_book.visible = true
		sound.play()
	var text_l = book.get(page,"")
	var text_r = book.get(page+1,"")
	if text_l is String:
		book_text_l.show_text(text_l, 24)
		image_l.texture = null
	else:
		book_text_l.text = ""
		image_l.modulate.a = 1.0
		image_l.texture = text_l[0]
		image_l.visible = true
		if text_l[1]:
			image_l.play_disappear_animation()
			book.erase(page)
			get_item.emit([text_l[2]])
	if text_r is String:
		book_text_r.show_text(text_r, 24)
		image_r.texture = null
	else:
		book_text_r.text = ""
		image_r.texture = text_r[0]
		image_r.modulate.a = 1.0
		image_r.texture = text_r[0]
		image_r.visible = true
		if text_r[1]:
			image_r.play_disappear_animation()
			book.erase(page)
			get_item.emit([text_r[2]])
		
func _move():
	if not visible:
		return
	move_button.release_focus()
	move_mob = !move_mob
	if move_mob:
		item_details_text.show_text("选择要移动的物品，按下ENTER或鼠标左键以确认，再次按下M以退出移动模式", 24)
		view_button.visible = false
		move_button.text = "CANCEL"
	else:
		move_button.text = "MOVE"
		move_slot = -1
		move_mob = false
		item_details_text.show_text("", 24)
		Item_Move.texture = null
		_show_item()

func _close():
	sound.play()
	player._action(true)
	visible = false
	exit_button.release_focus()

func _on_slot_clicked(idx):
	item_zone_id = idx
	show_item_zone(item_zone_id)
	if move_mob:
		move_item()

func move_item():
	if view_book.visible:
		return
	if move_slot == -1:
		move_slot = item_zone_id
		item_details_text.show_text("请选择要移动的位置，按下ENTER或鼠标左键以确认，再次按下M以退出移动模式", 24)
	else:
		var ori_item = item_list[item_zone_id]
		var new_item = item_list[move_slot]
		item_list[item_zone_id] = new_item
		item_list[move_slot] = ori_item
		move_slot = -1
		move_mob = false
		move_button.text = "MOVE"
		item_details_text.show_text("", 24)
		InventoryManager.slots = item_list.slice(0,10)
		InventoryManager.back_pack = item_list.slice(10,20)
		InventoryManager.inventory_updated.emit()
		Item_Move.texture = null
		_show_item()
		_show_item_details()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("backpack"):
		sound.play()
		visible = true
		player._action(false)
		_show_item()
		move_mob = false
		move_slot = -1
		move_button.text = "MOVE"
		item_details_text.show_text("", 24)
		Item_Move.texture = null
		_show_item()
	if not visible or view_book.visible:
		return
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		if item_zone_id < 19:
			item_zone_id += 1
		else:
			item_zone_id = 0
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		if item_zone_id > 0:
			item_zone_id -= 1
		else:
			item_zone_id = 19
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		if item_zone_id > 4:
			item_zone_id -= 5
		else:
			item_zone_id = 15 + item_zone_id
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		if item_zone_id <15:
			item_zone_id += 5
		else:
			item_zone_id = item_zone_id%5
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if item_zone_id > 0:
						item_zone_id -= 1
					else:
						item_zone_id = 9
				MOUSE_BUTTON_WHEEL_DOWN:
					if item_zone_id < 19:
						item_zone_id += 1
					else:
						item_zone_id = 0
	if event.is_action_pressed("continue"):
		if move_mob:
			move_item()
	show_item_zone(item_zone_id)
	item_id = item_list[item_zone_id]
	if move_slot == -1:
		if item_id != -1:
			_show_item_name()
			_show_item_image(item_id)
	else:
		var item_move_texture = InventoryManager.get_item_texture(item_list[move_slot])
		if item_move_texture:
			Item_Move.texture = load(InventoryManager.get_item_texture(item_list[move_slot]))
		item_slots[move_slot].texture = null
		Item_Move.position = Vector2(item_slots[item_zone_id].position.x,item_slots[item_zone_id].position.y)
		_show_item_image(item_list[move_slot])
	if not move_mob and item_id != -1:
		_show_item_details()

func show_item_zone(id):
	item_zone.position = Vector2(item_slots[id].position.x-5,item_slots[id].position.y-7.5)

func _show_item():
	slots = InventoryManager.slots
	for item in slots.size():
		if slots[item] == -1:
			item_slots[item].texture = null
			continue
		item_slots[item].texture = load(InventoryManager.get_item_texture(slots[item]))
	back_pack = InventoryManager.back_pack
	for item in back_pack.size():
		if back_pack[item] == -1:
			item_slots[item + 10].texture = null
			continue
		item_slots[item + 10].texture = load(InventoryManager.get_item_texture(back_pack[item]))
	item_list = slots + back_pack

func _show_item_name():
	var text = InventoryManager.ITEM_DATA[item_id]["name"]
	item_name_text.show_text(text, 40)

func _show_item_image(id):
	var image = InventoryManager.get_item_texture(id)
	if image:
		item_details.texture = load(image)
	else:
		item_details.texture = null

func _show_item_details():
	if item_id == -1:
		return
	var text = InventoryManager.ITEM_DATA[item_id].get("more", InventoryManager.ITEM_DATA[item_id]["name"])
	item_details_text.show_text(text, 24)
	var view = InventoryManager.ITEM_DATA[item_id].get("view")
	if view:
		view_button.visible = true
		book = ViewBook.book[view]
		page = book.get("page",0)
	else:
		view_button.visible = false
