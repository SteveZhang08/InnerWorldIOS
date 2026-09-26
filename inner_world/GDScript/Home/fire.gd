extends AnimatedSprite2D
@onready var sound = $Sound


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play("fire")
	sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
