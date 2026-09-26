extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = is_mobile()

func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
