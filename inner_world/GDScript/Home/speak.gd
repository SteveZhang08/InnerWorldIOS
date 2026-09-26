extends Panel

@onready var item = $Item
@onready var text_lable = $RichTextLabel
@onready var continue_button = $continue
@onready var skip_button = $skip
@onready var click_sound = $Click

signal player_action(tf:bool)
signal next()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_close)
	skip_button.pressed.connect(_skip)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _close():
	if visible:
		visible = false
		click_sound.play()
		text_lable.sound.stop()
		player_action.emit(true)
		next.emit()

func _skip():
	if visible:
		click_sound.play()
		text_lable.sound.stop()
		text_lable.skip_typing()

var item_id = 0
var text = "这是默认数据。正常情况下你不应该看见它"

func _show(item_id, text):
	visible = true
	item.texture = load(InventoryManager.get_item_texture(item_id))
	player_action.emit(false)
	await text_lable.show_text(text,24)
	return

func _error(texting):
	item.texture = load(InventoryManager.get_item_texture(item_id))
	player_action.emit(false)
	text += str(texting)
	text_lable.show_text(text,24)
