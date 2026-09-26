extends Sprite2D

var speed = 200
var angle_speed = 1

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_right"):
		position.x = position.x + 5
	if Input.is_action_pressed("move_left"):
		position.x = position.x - 5
	if Input.is_action_pressed("move_up"):
		position.y = position.y - 5
	if Input.is_action_pressed("move_down"):
		position.y = position.y + 5
