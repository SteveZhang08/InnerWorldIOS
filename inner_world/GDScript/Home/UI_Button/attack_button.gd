extends Button

@onready var player = Global_Player.player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(player.attack)
