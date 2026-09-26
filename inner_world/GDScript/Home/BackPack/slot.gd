extends TextureRect

signal clicked(slot_index)   # 自定义信号，携带槽位索引

var slot_index: int

func _ready():
	slot_index = name.get_slice("_", 1).to_int()
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(slot_index)
