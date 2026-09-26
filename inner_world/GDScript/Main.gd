extends Node2D

@onready var world_container = $WorldContainer
@onready var player = Global_Player.player

var current_interactive
var current_room

func _ready():
	# 游戏启动时加载主房间
	load_room("res://tscn/main_home.tscn")
# 加载指定路径的房间，并自动寻找出生点
func load_room(room_path: String):
	# 1. 移除旧房间和旧 Interactive
	if current_interactive:
		current_interactive.queue_free()
	if current_room:
		current_room.queue_free()

	# 2. 加载新房间
	var room_resource = load(room_path)
	if not room_resource:
		return
	var room_instance = room_resource.instantiate()
	current_room = room_instance
	world_container.add_child(room_instance)  # 放在 WorldContainer 下（包含背景）

	# 3. 提取 Interactive 节点（假设在 Room 下名为 "Interactive"）
	var interactive = room_instance.get_node("Interactive")
	if interactive:
		# 从 Room 中移除，添加到 YSort 下
		room_instance.remove_child(interactive)
		$YSort.add_child(interactive)  # 与 Player 同级
		current_interactive = interactive

	# 4. 查找玩家出生点
	var spawn = room_instance.find_child("Spawn_Point", true, false)
	if spawn:
		player.global_position = spawn.global_position
	else:
		push_warning("房间中未找到 Spawn_Point: ", room_path)
		# 如果没有找到出生点，默认放在 (0, 0)
		player.global_position = Vector2.ZERO
