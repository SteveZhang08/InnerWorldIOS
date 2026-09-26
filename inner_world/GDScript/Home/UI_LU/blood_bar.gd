extends TextureRect

var blood

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blood = 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var new_blood = Global_Player.player.blood
	if new_blood != blood:
		if blood > 0:
			scale.x = new_blood/100.0
		else:
			texture = null
		blood = new_blood
