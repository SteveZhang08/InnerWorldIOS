extends Button

@onready var hint = Global_Player.hint

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(attack)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func attack():
	hint._action()
