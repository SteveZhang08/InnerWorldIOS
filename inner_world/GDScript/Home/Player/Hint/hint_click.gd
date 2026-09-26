extends Panel

@onready var hint = Global_Player.hint

func _ready():
	modulate = Color(1, 1, 1, 0)  # 完全透明
	mouse_filter = MOUSE_FILTER_STOP  # 确保捕获鼠标事件

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 调用 hint 的 _action() 方法
		if hint and hint.has_method("_action"):
			hint._action()
