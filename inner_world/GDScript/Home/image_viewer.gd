extends Panel

signal player_action(tf:bool)
@onready var image_lable = $TextureRect
@onready var text_lable = $RichTextLabel
@onready var close_button = $Button
@onready var click_sound = $Click
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	close_button.pressed.connect(_close)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _close():
	if visible:
		click_sound.play()
		visible = false
		player_action.emit(true)

func _show(item_id:int, text:String):
	visible = true
	player_action.emit(false)
	var image = load(InventoryManager.get_item_texture(item_id))
	image_lable.texture = image
	text_lable.show_text(text, 24)
