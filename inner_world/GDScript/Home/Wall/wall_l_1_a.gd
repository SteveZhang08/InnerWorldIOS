extends Sprite2D

var materials = CanvasItemMaterial.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	materials.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = materials


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var time = GlobalTime.get_time_hours()
	if time >= 18.9:
		material = null
	elif time >= 5.4:
		material = materials
