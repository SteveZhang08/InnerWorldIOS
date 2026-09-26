extends Sprite2D

@export var up: Texture2D   # 状态1：提示按 E
@export var press: Texture2D  # 状态2：按下/交互后的状态
@onready var sound = $press

signal _finished()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	texture = up

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent):
	if event.is_action_pressed("interact") and visible:
		_action()

func _action():
	texture = press
	sound.play()
	await get_tree().create_timer(0.2).timeout
	_finished.emit()
	texture = up
	await get_tree().create_timer(0.1).timeout
	visible = false
