extends TextureRect

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var simulated_event = InputEventAction.new()
		simulated_event.action = "backpack"
		simulated_event.pressed = true
		Input.parse_input_event(simulated_event)
