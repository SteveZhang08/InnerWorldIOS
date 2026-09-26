extends StaticBody2D

var initially_y
var chair_collision

@onready var interaction_zone = $InteractionZone
@onready var hint = Global_Player.hint

signal show_info(item_id, text)
var self_status

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chair_collision = $chairCollisionShape2D
	initially_y = chair_collision.position.y
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	show_info.connect(get_node("/root/Main/UI/Speak")._show)
	hint._finished.connect(_e_press)

func _e_press():
	if player_entered:
		action()

var player_entered

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_entered = true
		hint.visible = true

func action():
	show_info.emit(4,"一个奇怪的地球仪，看起来年纪比我都大。\n这上面陆地看起来很广袤，还有好大的...湖泊？\n等等。那个最大的水体，标签上写的不是“海”——是“湖”。")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_entered = false
		hint.visible = false

func _move(status:String):
	if status == "up":
		self.z_index = 1
		chair_collision.position.y = initially_y + 30
	elif status == "down":
		self.z_index = 0
		chair_collision.position.y = initially_y

func _process(delta: float) -> void:
	if Global_Player.player.position_y <= 300 and self_status != "up":
		#_move("up")
		self_status = "up"
	elif Global_Player.player.position_y > 300 and self_status != "down":
		#_move("down")
		self_status = "down"
