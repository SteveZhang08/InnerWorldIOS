extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#visible = true
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _move(status:String):
	if status == "up":
		#visible = true
		pass
	elif status == "down":
		#visible = false
		pass
