extends Node

var player
var hint
var think
var InventoryBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node("/root/Main/YSort/Player")
	hint = get_node("/root/Main/YSort/Player/Hint")
	think = get_node("/root/Main/YSort/Player/think")
	InventoryBar = get_node("/root/Main/UI/InventoryBar")

func _is_weapon() -> bool:
	if InventoryBar._get_item_id() == 2:
		return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
