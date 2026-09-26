extends Sprite2D

@onready var item_image = $item
@onready var text_panel = $ThinkText

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate.a = 0.0
	visible = true
	pass # Replace with function body.

func _show(item_id=false, text=false):
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	if item_id:
		item_image.texture = load(InventoryManager.get_item_texture(item_id))
	if text:
		text_panel.show_text(text, 10)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
