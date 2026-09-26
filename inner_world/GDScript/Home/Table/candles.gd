extends AnimatedSprite2D
@onready var interaction_zone = $InteractionZone
@onready var hint = Global_Player.hint
@onready var light = $PointLight2D
@onready var fire_sound = $Fire
@onready var unfire_sound = $UnFire

var fire = 0

signal show_image(item_id, text)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	show_image.connect(get_node("/root/Main/UI/ImageViewer")._show)
	hint._finished.connect(_e_press)
	animation = "default"
	frame = 0
	light.visible = false

func _e_press():
	if player_entered:
		action()

var player_entered

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_entered = true
		hint.visible = true

func action():
	fire = 1-fire
	animation = "default"
	if fire:
		fire_sound.play()
	else:
		unfire_sound.play()
	frame = fire
	light.visible = fire

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_entered = false
		hint.visible = false
