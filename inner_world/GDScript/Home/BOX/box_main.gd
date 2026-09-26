extends StaticBody2D

# ---------- 节点引用 ----------
@onready var interaction_zone = $InteractionZone
@onready var bookshelf_sprite = $Sprite2D
@onready var hint = Global_Player.hint
@onready var item_list = $Item_List
@onready var sound = $Sound

# ---------- 状态变量 ----------
var is_player_near = false
var is_open = false

signal get_item(item:int)

# ---------- 初始化 ----------
func _ready():
	# 连接信号
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	hint._finished.connect(_e_press)
	var target_node = get_node("/root/Main/UI/Get_Item_Info")
	get_item.connect(target_node._on_bookshelf_get_item)

func _e_press():
	if is_open:
		return
	if is_player_near:
		perform_action()

# ---------- 玩家进出检测 ----------
func _on_body_entered(body):
	if body.is_in_group("player"):
		if is_open:
			is_player_near = false
			return
		is_player_near = true
		hint.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_near = false
		hint.visible = false

# ---------- 交互逻辑 ----------
func perform_action():
	if is_open:
		return
	get_item.emit(item_list.list)
	is_open = true
	if sound:
		sound.play()
