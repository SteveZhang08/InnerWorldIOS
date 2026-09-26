extends Sprite2D

@onready var sound = $AudioStreamPlayer2D
@onready var main_sound = $Train_Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y += 100*delta
