extends Node

var player
var hint
var think

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node("/root/Main/YSort/Player")
	hint = get_node("/root/Main/YSort/Player/Hint")
	think = get_node("/root/Main/YSort/Player/think")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
