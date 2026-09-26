extends Area2D

signal clicked(position: Vector2)
@onready var Player = Global_Player.player

func _ready():
	input_event.connect(_on_input_event)
	clicked.connect(Player._on_mouse_click_move)

func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 使用 get_global_mouse_position() 获取准确的世界坐标
		var world_mouse_pos = get_global_mouse_position()
		clicked.emit(world_mouse_pos)
		get_viewport().set_input_as_handled()
