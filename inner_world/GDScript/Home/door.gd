extends Sprite2D

@onready var think_panel = Global_Player.think
@onready var interaction_zone = $InteractionZone
@onready var InventoryBar = get_node("/root/Main/UI/InventoryBar")
@onready var hint = Global_Player.hint

signal _think(item_id, text)

var player_entered = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_think.connect(think_panel._show)
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	hint._finished.connect(_e_press)

func _e_press():
	if player_entered:
		var main = get_tree().current_scene
		main.load_room("res://tscn/stairwell.tscn")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_entered = true
		if InventoryBar._get_item_id() == 3:
			think_panel.visible = false
			hint.visible = true
		else:
			think_panel.visible = true
			_think.emit(3,"NEED")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_entered = false
		think_panel.visible = false
		hint.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_entered:
		if InventoryBar._get_item_id() == 3:
			think_panel.visible = false
			hint.visible = true
		else:
			hint.visible = false
			think_panel.visible = true
