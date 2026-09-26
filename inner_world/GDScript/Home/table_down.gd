extends StaticBody2D

@onready var collision_shape = $CollisionPolygon2D
@onready var interaction_zone = $InteractionZone
@onready var hint = Global_Player.hint
var initially_y
var self_status

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initially_y = collision_shape.position.y
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	show_info.connect(get_node("/root/Main/UI/Speak")._show)
	hint._finished.connect(_e_press)

func _move(status:String):
	if status == "up":
		self.z_index = 1
		collision_shape.position.y = initially_y + 27
	elif status == "down":
		self.z_index = 0
		collision_shape.position.y = initially_y

signal show_info(item_id, text)

func _e_press():
	if player_entered:
		action()

var player_entered

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_entered = true
		hint.visible = true

func action():
	show_info.emit(12,"小盒里是几片干涩的褐色药片。闻起来有苦味。水杯内壁有一圈水渍，已经干了")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_entered = false
		hint.visible = false

func _process(delta: float) -> void:
	if Global_Player.player.position_y <= 340 and self_status != "up":
		#_move("up")
		self_status = "up"
	elif Global_Player.player.position_y > 426.57 and self_status != "down":
		#_move("down")
		self_status = "down"
