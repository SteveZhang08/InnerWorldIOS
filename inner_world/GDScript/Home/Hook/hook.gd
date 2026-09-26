extends StaticBody2D

@onready var interaction_zone = $InteractionZone
@onready var hint = Global_Player.hint

signal show_info(item_id, text)

func _ready() -> void:
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
	show_info.emit(0,"门边的墙上钉着四个黄铜挂钩。有三个都空着。
第三个挂钩挂着的一块破布上，用写着一行小字：“我把东西从钩子上拿下来了。我老觉得那样挂着太显眼。放在一个能记住的地方就好。”
铅笔。字迹很轻，像是写的人不确定自己该不该留下这句话。")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_entered = false
		hint.visible = false
