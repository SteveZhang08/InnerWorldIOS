extends StaticBody2D
@onready var interaction_zone = $InteractionZone
@onready var hint = Global_Player.hint

signal show_image(item_id, text)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	show_image.connect(get_node("/root/Main/UI/ImageViewer")._show)
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
	show_image.emit(7,"一个看起来年代久远的地图。\nHoly Swite Kingdom：神圣斯威特王国。Abyssia 渊都 · Cardis 枢机城 · Norwick 北望港\nMirram 镜澜 · Granvelle 穗原 · Ironspine 铁脊关。")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_entered = false
		hint.visible = false
