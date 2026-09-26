extends Button

@onready var player = Global_Player.player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(player.attack)

func _process(delta: float) -> void:
	visible = Global_Player._is_weapon()
