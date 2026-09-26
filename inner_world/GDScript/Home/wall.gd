extends StaticBody2D

@onready var interaction_zone = $mirrorInteractionZone
@onready var hint = Global_Player.hint
@onready var speak = get_node("/root/Main/UI/Speak")

signal show_info(item_id, text)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	hint._finished.connect(_e_press)
	show_info.connect(get_node("/root/Main/UI/Speak")._show)

var player_enter = false

func _e_press():
	var string = [
		[6, "镜子里是一张陌生的脸。\n你盯着它看了很久。深色的头发，略微凹陷的眼窝，左眉骨上方有一道很浅的旧疤痕——你不记得它是怎么来的。\n你抬起右手，镜中人也抬起右手。你凑近，他也凑近。"],
		[6, "这不是你的脸。但它在看着你，像是在等你想起来。\n你占据了一个人。你不知道他的名字，不知道他做过什么、欠过什么、被许诺过什么。但此刻他在镜子里看着你，等你替他想起这一切。"],
		[0, "我这是穿越了吗？这里是哪，我现在是谁？"]]
	if player_enter:
		for textlist in string:
			show_info.emit(textlist[0], textlist[1])
			await speak.next

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_enter = true
		hint.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_enter = false
		hint.visible = false
